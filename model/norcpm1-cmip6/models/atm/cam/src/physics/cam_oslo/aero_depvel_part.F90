  subroutine aero_depvel_part( ncol, t, pmid, ram1, fv, vlc_dry, vlc_trb, vlc_grv,  &
                     radius_part, density_part, sig_part, moment, lchnk )

!    calculates surface deposition velocity of particles
!    L. Zhang, S. Gong, J. Padro, and L. Barrie
!    A size-seggregated particle dry deposition scheme for an atmospheric aerosol module
!    Atmospheric Environment, 35, 549-560, 2001.
!
!    Authors: X. Liu
! O. Seland Adapted to the structure used in CAM-Oslo. 

    !
    ! !USES
    !
    use shr_const_mod, only: SHR_CONST_PI, SHR_CONST_BOLTZ
    use physconst,     only: gravit, rair
    use drydep_so2,     only: fraction_landuse
    use phys_grid,     only: get_lat_all_p, get_lon_all_p
    use shr_kind_mod, only: r8 => shr_kind_r8
    use ppgrid,      only: pcols, pver
    use aerosoldef
    ! !ARGUMENTS:
    !
    implicit none
    !
    real(r8) :: t(pcols,pver)       !atm temperature (K)
    real(r8) :: pmid(pcols,pver)    !atm pressure (Pa)
    real(r8) :: fv(pcols)           !friction velocity (m/s)
    real(r8) :: ram1(pcols)         !aerodynamical resistance (s/m)
    real(r8) :: vlc_trb(pcols)       !Turbulent deposn velocity (m/s)
    real(r8) :: vlc_grv(pcols,pver)       !grav deposn velocity (m/s)
    real(r8) :: vlc_dry(pcols,pver)       !dry deposn velocity (m/s)
    real(r8) :: radius_part(pcols,pver)    ! mean (volume/number) particle radius (m)
    real(r8) :: density_part(pcols,pver)   ! density of particle material (kg/m3)
    real(r8) :: sig_part(pcols,pver)       ! geometric standard deviation of particles
    integer, intent(in) :: moment ! moment of size distribution (0 for number, 2 for surface area, 3 for volume)
    integer, intent(in) :: ncol
    integer, intent(in) :: lchnk

    !------------------------------------------------------------------------

    !------------------------------------------------------------------------
    ! Local Variables
    integer  :: m,i,k,ix                !indices
    real(r8) :: rho     !atm density (kg/m**3)
    real(r8) :: vsc_dyn_atm(pcols,pver)   ![kg m-1 s-1] Dynamic viscosity of air
    real(r8) :: vsc_knm_atm(pcols,pver)   ![m2 s-1] Kinematic viscosity of atmosphere
    real(r8) :: shm_nbr       ![frc] Schmidt number
    real(r8) :: stk_nbr       ![frc] Stokes number
    real(r8) :: mfp_atm(pcols,pver)       ![m] Mean free path of air
    real(r8) :: dff_aer       ![m2 s-1] Brownian diffusivity of particle
    real(r8) :: slp_crc(pcols,pver) ![frc] Slip correction factor
    real(r8) :: rss_trb       ![s m-1] Resistance to turbulent deposition
    real(r8) :: rss_lmn       ![s m-1] Quasi-laminar layer resistance
    real(r8) :: brownian      ! collection efficiency for Browning diffusion
    real(r8) :: impaction     ! collection efficiency for impaction
    real(r8) :: interception  ! collection efficiency for interception
    real(r8) :: stickfrac     ! fraction of particles sticking to surface
    real(r8) :: radius_moment(pcols,pver) ! median radius (m) for moment
    real(r8) :: lnsig         ! ln(sig_part)
    real(r8) :: dispersion    ! accounts for influence of size dist dispersion on bulk settling velocity
                              ! assuming radius_part is number mode radius * exp(1.5 ln(sigma))

    integer  :: latndx(pcols)                         ! chunk lat indicies
    integer  :: lonndx(pcols)                         ! chunk lon indicies
    integer  :: lt
    real(r8) :: lnd_frc
    real(r8) :: wrk1, wrk2, wrk3

    ! constants
    real(r8) gamma(11)      ! exponent of schmidt number
!   data gamma/0.54d+00,  0.56d+00,  0.57d+00,  0.54d+00,  0.54d+00, &
!              0.56d+00,  0.54d+00,  0.54d+00,  0.54d+00,  0.56d+00, &
!              0.50d+00/
    data gamma/0.56d+00,  0.54d+00,  0.54d+00,  0.56d+00,  0.56d+00, &        
               0.56d+00,  0.50d+00,  0.54d+00,  0.54d+00,  0.54d+00, &
               0.54d+00/
    save gamma

    real(r8) alpha(11)      ! parameter for impaction
!   data alpha/50.00d+00,  0.95d+00,  0.80d+00,  1.20d+00,  1.30d+00, &
!               0.80d+00, 50.00d+00, 50.00d+00,  2.00d+00,  1.50d+00, &
!             100.00d+00/
    data alpha/1.50d+00,   1.20d+00,  1.20d+00,  0.80d+00,  1.00d+00, &
               0.80d+00, 100.00d+00, 50.00d+00,  2.00d+00,  1.20d+00, &
              50.00d+00/
    save alpha

    real(r8) radius_collector(11) ! radius (m) of surface collectors
!   data radius_collector/-1.00d+00,  5.10d-03,  3.50d-03,  3.20d-03, 10.00d-03, &
!                          5.00d-03, -1.00d+00, -1.00d+00, 10.00d-03, 10.00d-03, &
!                         -1.00d+00/
    data radius_collector/10.00d-03,  3.50d-03,  3.50d-03,  5.10d-03,  2.00d-03, &
                           5.00d-03, -1.00d+00, -1.00d+00, 10.00d-03,  3.50d-03, &
                          -1.00d+00/
    save radius_collector

    integer            :: iwet(11) ! flag for wet surface = 1, otherwise = -1
!   data iwet/1,   -1,   -1,   -1,   -1,  &
!            -1,   -1,   -1,    1,   -1,  &
!             1/
    data iwet/-1,  -1,   -1,   -1,   -1,  &
              -1,   1,   -1,    1,   -1,  &
              -1/
    save iwet

!    if ( allocated(fraction_landuse) ) then
       call get_lat_all_p( lchnk, ncol, latndx )
       call get_lon_all_p( lchnk, ncol, lonndx )
!    endif

    !------------------------------------------------------------------------
    do k=1,pver
       do i=1,ncol

          lnsig = log(sig_part(i,k))
! use a maximum radius of 50 microns when calculating deposition velocity
          radius_moment(i,k) = min(50.0e-6_r8,radius_part(i,k))*   &
                          exp((real(moment,r8)-1.5_r8)*lnsig*lnsig)
          dispersion = exp(2._r8*lnsig*lnsig)

          rho=pmid(i,k)/rair/t(i,k)

          ! Quasi-laminar layer resistance: call rss_lmn_get
          ! Size-independent thermokinetic properties
          vsc_dyn_atm(i,k) = 1.72e-5_r8 * ((t(i,k)/273.0_r8)**1.5_r8) * 393.0_r8 / &
               (t(i,k)+120.0_r8)      ![kg m-1 s-1] RoY94 p. 102
          mfp_atm(i,k) = 2.0_r8 * vsc_dyn_atm(i,k) / &   ![m] SeP97 p. 455
               (pmid(i,k)*sqrt(8.0_r8/(SHR_CONST_PI*rair*t(i,k))))
          vsc_knm_atm(i,k) = vsc_dyn_atm(i,k) / rho ![m2 s-1] Kinematic viscosity of air

          slp_crc(i,k) = 1.0_r8 + mfp_atm(i,k) * &
                  (1.257_r8+0.4_r8*exp(-1.1_r8*radius_moment(i,k)/(mfp_atm(i,k)))) / &
                  radius_moment(i,k)   ![frc] Slip correction factor SeP97 p. 464
          vlc_grv(i,k) = (4.0_r8/18.0_r8) * radius_moment(i,k)*radius_moment(i,k)*density_part(i,k)* &
                  gravit*slp_crc(i,k) / vsc_dyn_atm(i,k) ![m s-1] Stokes' settling velocity SeP97 p. 466
          vlc_grv(i,k) = vlc_grv(i,k) * dispersion

          vlc_dry(i,k)=vlc_grv(i,k)
       enddo
    enddo
    k=pver  ! only look at bottom level for next part
    do i=1,ncol
       dff_aer = SHR_CONST_BOLTZ * t(i,k) * slp_crc(i,k) / &    ![m2 s-1]
                 (6.0_r8*SHR_CONST_PI*vsc_dyn_atm(i,k)*radius_moment(i,k)) !SeP97 p.474
       shm_nbr = vsc_knm_atm(i,k) / dff_aer                        ![frc] SeP97 p.972

       wrk2 = 0._r8
       wrk3 = 0._r8

       do lt = 1,n_land_type
          lnd_frc = fraction_landuse(lonndx(i),latndx(i),lt)
!          write(6,*) i,lt,lnd_frc
!          lnd_frc=0._r8
!          if (lt.eq.7) lnd_frc=1._r8          
!fraction_landuse(lonndx(i),latndx(i),lt)
          if ( lnd_frc /= 0._r8 ) then
             brownian = shm_nbr**(-gamma(lt))
             if (radius_collector(lt)  > 0.0d0) then
!       vegetated surface
                stk_nbr = vlc_grv(i,k) * fv(i) / (gravit*radius_collector(lt))
                interception = 2.0_r8*(radius_moment(i,k)/radius_collector(lt))**2.0_r8
             else
!       non-vegetated surface
                stk_nbr = vlc_grv(i,k) * fv(i) * fv(i) / (gravit*vsc_knm_atm(i,k))  ![frc] SeP97 p.965
                interception = 0.0_r8
             endif
             impaction = (stk_nbr/(alpha(lt)+stk_nbr))**2.0_r8   

             if (iwet(lt) > 0) then
                stickfrac = 1.0_r8
             else
                stickfrac = exp(-sqrt(stk_nbr))
                if (stickfrac < 1.0d-10) stickfrac = 1.0d-10
             endif
             rss_lmn = 1.0_r8 / (3.0_r8 * fv(i) * stickfrac * (brownian+interception+impaction))
             rss_trb = ram1(i) + rss_lmn + ram1(i)*rss_lmn*vlc_grv(i,k)

             wrk1 = 1.0_r8 / rss_trb
             wrk2 = wrk2 + lnd_frc*( wrk1 )
             wrk3 = wrk3 + lnd_frc*( wrk1 + vlc_grv(i,k) )
          endif
       enddo  ! n_land_type
       vlc_trb(i) = wrk2
       vlc_dry(i,k) = wrk3
    enddo !ncol
    return
  end subroutine aero_depvel_part
