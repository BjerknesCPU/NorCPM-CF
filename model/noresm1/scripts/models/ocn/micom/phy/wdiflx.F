      subroutine wdiflx
c
c --- Write accumulated diagnosed heat and salt fluxes
c
      use mod_xc
      use mod_nctools
c
      implicit none
c
#include "common_blocks.h"
#include "common_clndr.h"
#include "common_forc.h"
c
      character fname*120
      integer i,j,k
c
      if (ditflx) then
c
        write (fname,'(2a,i4.4,a)')
     .    runid(1:runid_len),'_tflxdi_',nyear-1,'.nc'
        if (mnproc.eq.1) then
          write (lp,'(2a)')
     .      'Writing diagnostic heat flux to ',path1(1:path1_len)//fname
        endif
        call ncfopn(path1(1:path1_len)//fname,'w','c',1)
c
#ifdef COMPDIA
        call ncdimc('pcomp',ip,0)
#else
        call ncdims('x',itdm)
        call ncdims('y',jtdm)
#endif 
        call ncdims('week',48)
c
        call ncputr('time',time)
        call ncputi('nflxdi',nflxdi)
c
#ifdef COMPDIA
        call nccomp('tflxdi','pcomp week',tflxdi,ip,1.,0.,8)
#else
        call ncwrtr('tflxdi','x y week',tflxdi,ip,1,1.,0.,8)
#endif 
c       
        call ncfcls
c
c$OMP PARALLEL DO
        do k=1,48
          nflxdi(k)=0
          do j=1,jj
            do i=1,ii
              tflxdi(i,j,k)=0.
            enddo
          enddo
        enddo
c$OMP END PARALLEL DO
c
      endif
c
      if (disflx) then
c
        write (fname,'(2a,i4.4,a)')
     .    runid(1:runid_len),'_sflxdi_',nyear-1,'.nc'
        if (mnproc.eq.1) then
          write (lp,'(2a)')
     .      'Writing diagnostic salt flux to ',path1(1:path1_len)//fname
        endif
        call ncfopn(path1(1:path1_len)//fname,'w','c',1)
c
#ifdef COMPDIA
        call ncdimc('pcomp',ip,0)
#else
        call ncdims('x',itdm)
        call ncdims('y',jtdm)
#endif 
        call ncdims('week',48)
c
        call ncputr('time',time)
        call ncputi('nflxdi',nflxdi)
c
#ifdef COMPDIA
        call nccomp('sflxdi','pcomp week',sflxdi,ip,1.,0.,8)
#else
        call ncwrtr('sflxdi','x y week',sflxdi,ip,1,1.,0.,8)
#endif 
c       
        call ncfcls
c
c$OMP PARALLEL DO
        do k=1,48
          nflxdi(k)=0
          do j=1,jj
            do i=1,ii
              sflxdi(i,j,k)=0.
            enddo
          enddo
        enddo
c$OMP END PARALLEL DO
c
      endif
c
      return
      end
