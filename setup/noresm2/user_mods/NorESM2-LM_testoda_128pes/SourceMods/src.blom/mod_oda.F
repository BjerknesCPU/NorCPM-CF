      module mod_oda

      use mod_xc, only: lp, mnproc
      use mod_time

      implicit none

      contains

      subroutine oda()
c
      implicit none
c
      logical :: ldooda,lpause
c
      if (mod(nstep,nstep_in_day).ne.0) return 
      inquire(file='../../DA/BLOM_DA',exist=ldooda)
      if (ldooda) then 
        if (mnproc.eq.1) then
          write (lp,*) 'Perform ODA ', date%year, date%month, date%day
        endif
c
        call restart_wt_oda
c
        if (mnproc.eq.1) then
          write(lp,*)'ODA pause at ',rdate()
          open(unit=999,file='../../DA/BLOM_PAUSE_'//member_tag(),
     .      status='replace',action='write')
          write(999,'(A)') rdate() 
          close(999)
          lpause = .true.
          do while ( lpause )
            call sleepqq(100) !! for sleep 0.1 sec
            inquire(file='../../DA/BLOM_PAUSE_'//member_tag(),
     .        exist=lpause)
              !! some process to DA, then delete the PAUSE file
          end do
          write(lp,*)'ODA pause finished, continue run'
        end if         
        call restart_rd_oda
      else
          write (lp,*) 'Skip ODA'
      endif 
c
      end subroutine oda


      character(len=3) function member_tag()
c
      implicit none
c
      character(len=3), save :: member_tag_saved='UNS'
      character(len=512) :: rundir
c
      if (member_tag_saved.eq.'UNS') then 
        call getcwd(rundir)
        member_tag_saved=rundir(LEN_TRIM(rundir)-6:LEN_TRIM(rundir)-4) 
      end if 
      member_tag = member_tag_saved
c
      end function member_tag


      character(len=10) function rdate()
c
      implicit none
c
      write(rdate,'(i4.4,"-",i2.2,"-",i2.2)') 
     .  date%year,date%month,date%day
c
      end function rdate


      character(len=512) function rstfnm_oda() 
c
      implicit none
c
      rstfnm_oda = 
     .  "../../DA/blom.da."//member_tag()//"."//rdate()//".nc"
c
      end function rstfnm_oda


      subroutine restart_rd_oda 
c
c --- ------------------------------------------------------------------
c --- Read initial conditions from restart file
c --- ------------------------------------------------------------------
c
      use mod_config, only: expcnf, runid, inst_suffix, resume_flag
      use mod_calendar, only: date_type, daynum_diff, operator(/=)
      use mod_time, only: date0, date, nday1, nstep0, nstep1
      use mod_xc
      use mod_vcoord, only: vcoord_type_tag, isopyc_bulkml, 
     .                      cntiso_hybrid
      use mod_inicon, only: icfile
      use mod_state, only: u, v, dp, dpu, dpv, temp, saln, sigma,
     .                     uflx, vflx, utflx, vtflx, usflx, vsflx,
     .                     phi, ubflxs, vbflxs,
     .                     ub, vb, pb, pbu, pbv, ubflxs_p, vbflxs_p,
     .                     pb_p, pbu_p, pbv_p, ubcors_p, vbcors_p,
     .                     sealv, kfpla
      use mod_pgforc, only: pgfx, pgfy, pgfxm, pgfym,
     .                      xixp, xixm, xiyp, xiym
      use mod_barotp, only: ubflx, vbflx, pb_mn, ubflx_mn, vbflx_mn,
     .                      pvtrop
      use mod_dia
      use mod_forcing, only: ditflx, disflx, sprfac,
     .                       tflxdi, sflxdi, nflxdi,
     .                       prfac, eiacc, pracc,
     .                       flxco2, flxdms, flxbrf, ustarb, buoyfl
      use mod_niw, only: uml, vml, umlres, vmlres
      use mod_difest, only: OBLdepth
      use mod_diffusion, only: difiso, Kvisc_m, Kdiff_t, Kdiff_s
      use mod_cesm, only: frzpot, mltpot, swa_da, nsf_da, hmlt_da,
     .                    lip_da, sop_da, eva_da, rnf_da, rfi_da,
     .                    fmltfz_da, sfl_da, ztx_da, mty_da, ustarw_da,
     .                    slp_da, abswnd_da, atmco2_da, atmbrf_da,
     .                    ficem_da, l1ci, l2ci
      use mod_ben02, only: cd_d, ch_d, ce_d, wg2_d, cd_m, ch_m, ce_m,
     .                     wg2_m, rhoa, tsi_tda, tml_tda, sml_tda,
     .                     alb_tda, fice_tda, ntda, rnfres
      use mod_thdysi, only: tsrfm, ticem
      use mod_seaice, only: ficem, hicem, hsnwm, iagem
      use mod_temmin, only: settemmin
#if defined(TRC) && (defined(TKE) || defined(IDLAGE))
      use mod_tracers, only: itrtke, itrgls, itriag, trc
#  ifdef TKE
      use mod_tke, only: L_scale
#  endif
#endif
c
      implicit none
c
      type(date_type) :: date_rest
      integer errstat,dndiff,i,j,n
      character(len=512) :: rstfnm,fnm
      character(len=2) :: c2
c
      integer, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy) :: iuu,ivv,iqq
      real, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy,2) :: rkfpla
      logical first,fexist,vexist
      data first /.true./
      save first,iuu,ivv,iqq

c
c --- - open restart file
      rstfnm = rstfnm_oda()
      if (mnproc.eq.1) inquire(file=rstfnm,exist=fexist)
      call xcbcst(fexist)
      if (fexist) then
      call ncfopn(rstfnm,'r',' ',1,iotype)
      else
        if (mnproc.eq.1) then
          write (lp,*) 'restart_rd_oda: could not find restart ', 
     .      trim(rstfnm)
        endif
        call xcstop('(restart_rd)')
      endif 
c
      if (mnproc.eq.1) then
        write (lp,'(2a)') ' restart_rd_oda: reading restart file ',
     .                    trim(rstfnm)
      endif
c
c --- Compute extended uv masks 
      if (first) then
        first=.false.
c$OMP PARALLEL DO PRIVATE(i)
        do j=1,jj
          do i=1,ii
            if ((ip(i,j)+ip(i-1,j)).ge.1) then
              iuu(i,j)=1
            else
              iuu(i,j)=0
            endif
            if ((ip(i,j)+ip(i,j-1)).ge.1) then
              ivv(i,j)=1
            else
              ivv(i,j)=0
            endif
            if ((iu(i,j)+iv(i,j)+iu(i,j-1)+iv(i-1,j)).ge.1) then
              iqq(i,j)=1
            else
              iqq(i,j)=0
            endif
          enddo 
        enddo
c$OMP END PARALLEL DO
      endif
c
      call ncread('dp',dp,ip,1,0.)
      call ncread('temp',temp,ip,1,0.)
      call ncread('saln',saln,ip,1,0.)
c
      call ncfcls
c
      return
      end subroutine restart_rd_oda 


      subroutine restart_wt_oda
c
c --- ------------------------------------------------------------------
c --- Write model state to restart files
c --- ------------------------------------------------------------------
c
      use mod_config, only: expcnf, runid, inst_suffix
      use mod_time, only: date0, date, nstep, nstep_in_day, nday_of_year
      use mod_xc
      use mod_vcoord, only: vcoord_type_tag, isopyc_bulkml, 
     .                      cntiso_hybrid
      use mod_state, only: u, v, dp, dpu, dpv, temp, saln, sigma,
     .                     uflx, vflx, utflx, vtflx, usflx, vsflx,
     .                     phi, ubflxs, vbflxs,
     .                     ub, vb, pb, pbu, pbv, ubflxs_p, vbflxs_p,
     .                     pb_p, pbu_p, pbv_p, ubcors_p, vbcors_p,
     .                     sealv, kfpla
      use mod_pgforc, only: pgfx, pgfy, pgfxm, pgfym,
     .                      xixp, xixm, xiyp, xiym
      use mod_barotp, only: ubflx, vbflx, pb_mn, ubflx_mn, vbflx_mn,
     .                      pvtrop
      use mod_dia
      use mod_forcing, only: ditflx, disflx, sprfac,
     .                       tflxdi, sflxdi, nflxdi,
     .                       prfac, eiacc, pracc,
     .                       flxco2, flxdms, ustarb, buoyfl,flxbrf
      use mod_niw, only: uml, vml, umlres, vmlres
      use mod_difest, only: OBLdepth
      use mod_diffusion, only: difiso, Kvisc_m, Kdiff_t, Kdiff_s
      use mod_cesm, only: frzpot, mltpot, swa_da, nsf_da, hmlt_da,
     .                    lip_da, sop_da, eva_da, rnf_da, rfi_da,
     .                    fmltfz_da, sfl_da, ztx_da, mty_da, ustarw_da,
     .                    slp_da, abswnd_da, atmco2_da, atmbrf_da,
     .                    ficem_da, l2ci
      use mod_ben02, only: cd_d, ch_d, ce_d, wg2_d, cd_m, ch_m, ce_m,
     .                     wg2_m, rhoa, tsi_tda, tml_tda, sml_tda,
     .                     alb_tda, fice_tda, ntda, rnfres
      use mod_thdysi, only: tsrfm, ticem
      use mod_seaice, only: ficem, hicem, hsnwm, iagem
#if defined(TRC) && (defined(TKE) || defined(IDLAGE))
      use mod_tracers, only: itrtke, itrgls, itriag, trc
#  ifdef TKE
      use mod_tke, only: L_scale
#  endif
#endif
c
      implicit none
c
      integer i,j,n
      character(len=256), dimension(4) :: rstdate_str
      character(len=512) :: rstfnm,fnm
      character(len=2) :: c2
      character(len=5) :: c5p,c5u,c5v,c5q
c
      integer, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy) :: iuu,ivv,iqq
      real, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy,2) :: rkfpla
      logical first
      data first /.true./
      save first,iuu,ivv,iqq
c
c --- formulate restart name and open restart file
c
      rstfnm = rstfnm_oda()
c
      if (rstfmt.eq.1) then 
        call ncfopn(rstfnm,'w','6',1,iotype)
      elseif (rstfmt.eq.2) then
        call ncfopn(rstfnm,'w','h',1,iotype)
      else
        call ncfopn(rstfnm,'w','c',1,iotype)
      endif
      call ncputi('nday0',date0%day)
      call ncputi('nmonth0',date0%month)
      call ncputi('nyear0',date0%year)
      call ncputr('time0',time0)
      call ncputr('time',time)
c
c --- define spatial and time dimensions
      if (first) then
        first=.false.
c$OMP PARALLEL DO PRIVATE(i)
        do j=1,jj
          do i=1,ii
            if ((ip(i,j)+ip(i-1,j)).ge.1) then
              iuu(i,j)=1
            else
              iuu(i,j)=0
            endif
            if ((ip(i,j)+ip(i,j-1)).ge.1) then
              ivv(i,j)=1
            else
              ivv(i,j)=0
            endif
            if ((iu(i,j)+iv(i,j)+iu(i,j-1)+iv(i-1,j)).ge.1) then
              iqq(i,j)=1
            else
              iqq(i,j)=0
            endif
          enddo 
        enddo
c$OMP END PARALLEL DO
      endif
      if (rstcmp.eq.1) then 
        call ncdimc('pcomp',ip,0)
        call ncdimc('qcomp',iqq,0)
        call ncdimc('ucomp',iuu,0)
        call ncdimc('vcomp',ivv,0)
        c5p='pcomp'
        c5u='ucomp'
        c5v='vcomp'
        c5q='qcomp'
      else
        call ncdims('x',itdm)
        call ncdims('y',jtdm)
        c5p='x y'
        c5u='x y'
        c5v='x y'
        c5q='x y'
      endif 
      call ncdims('k2',2)
      call ncdims('k3',3)
      call ncdims('k4',4)
      call ncdims('kk',kk)
      call ncdims('kkp1',kk+1)
      call ncdims('kk2',2*kk)
      call ncdims('plev',ddm)
      call ncputr('plev',depthslev)
      call ncdims('time',1)
c
c --- output model fields to restart file
c
      call defvar_restart(c5p,c5u,c5v,c5q)
      call wrtrst('dp',trim(c5p)//' kk2 time',dp,ip)
      call wrtrst('temp',trim(c5p)//' kk2 time',temp,ip)
      call wrtrst('saln',trim(c5p)//' kk2 time',saln,ip)
c
      call ncfcls
c
      return
      end


      subroutine wrtrst(vnm,dims,fld,msk)
c
c --- ------------------------------------------------------------------
      use mod_xc
      use mod_nctools
c
      implicit none
c 
      character(len=*) :: vnm,dims
      real, dimension(*) :: fld
      integer, dimension(*) :: msk
c
c --- Write data in compressed or uncompressed format
      if (dims(2:5).eq.'comp') then 
        call nccomp(vnm,dims,fld,msk,1.,0.,8)
      else
        call ncwrtr(vnm,dims,fld,msk,1,1.,0.,8)
      endif
c
      end

      subroutine defvar_restart(c5p,c5u,c5v,c5q)
c
c --- ------------------------------------------------------------------
      use mod_dia
      use mod_forcing, only: sprfac
c
      implicit none
c
      integer n
      character(len=2) :: c2
      character(len=5) :: c5p,c5u,c5v,c5q
c
      call defvarrst('dp',trim(c5p)//' kk2 time')
      call defvarrst('temp',trim(c5p)//' kk2 time')
      call defvarrst('saln',trim(c5p)//' kk2 time')
c
      call ncedef
c
      end 

      subroutine defvarrst(vnm,dims)
c
c --- ------------------------------------------------------------------
      use mod_nctools
c
      implicit none
c 
      character(len=*) :: vnm,dims

      call ncdefvar(vnm,dims,ndouble,8)
c
      end subroutine defvarrst

      end module mod_oda
