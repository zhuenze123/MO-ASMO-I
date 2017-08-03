function [M,negFn]=Giesekus_2M3D_v002(x,p)

    % Operating condition
    Omega = p.Omega;
    
    % Geometry
    Ntex = p.Ntex;
    ri = p.ri;
    ro = p.ro;
    
    % Mesh
    Nr = p.Nr;
    Nth = p.Nth;
    Nz = p.Nz;

    x_geom = x(1:((Nr+1)*Nth));
    x_fluid = x(((Nr+1)*Nth+1):end);

    % Surface Geometry
    % 2.69e-6 <= H(i,j) <= Hmax
    H = reshape(x_geom,Nr+1,Nth);
    H = [H, H(:,1)];
    
    % Fluid properties
    eta = p.eta;
    rho = p.rho;
    etap1 = x_fluid(1);
    etap2 = x_fluid(2);
    lambda1 = x_fluid(3);
    lambda2 = x_fluid(4);
    alpha1 = x_fluid(5);
    alpha2 = x_fluid(6);
    
    % Calculate derived parameters
    phi = 2*pi/Ntex;
    G1 = etap1/lambda1;
    G2 = etap2/lambda2;
    
    % r-direction
    [Kr,Mr,Cr,Dr,zr,wr] = semhat(Nr);
    Ir = speye(Nr+1);
    Resr = Ir(2:Nr,:);
    Pror = Resr';
    Nuemr0 = (Ir(2:Nr+1,:))';
    NuemrL = (Ir(1:Nr,:))';
    qr = zeros(1,Nr);
    qr(Nr)=1;
    Qr = sparse([qr;eye(Nr)]);
    
    % theta-direction
    [Kth,Mth,Cth,Dth,zth,wth] = semhat(Nth);
    Ith = speye(Nth+1);
    Resth = Ith(2:Nth,:);
    Proth = Resth';
    Nuemth0 = (Ith(2:Nth+1,:))';
    NuemthL = (Ith(1:Nth,:))';
    qth = zeros(1,Nth);
    qth(Nth) = 1;
    Qth = sparse([qth;eye(Nth)]);
    
    % z-direction
    [Kz,Mz,Cz,Dz,zz,wz] = semhat(Nz);
    Iz = speye(Nz+1);
    Resz = Iz(2:Nz,:);
    Proz = Resz';
    Nuemz0 = (Iz(2:Nz+1,:))';
    NuemzL = (Iz(1:Nz,:))';
    qz = zeros(1,Nz);
    qz(Nz) = 1;
    Qz = sparse([qz;eye(Nz)]);

    % 2D r, theta
    r = (1+zr)/2*ro+(1-zr)/2*ri;
    theta = phi/2*zth;
    [Rmat,Theta] = ndgrid(r,theta);
    r2d = kron(ones(Nth+1,1),r);
    theta2d = kron(theta,ones(Nr+1,1));
    J2d = ((ro-ri)/2)*(phi/2);
    w2d = kron(wth,wr);

    % 2D X, Y
    X2d = Rmat.*cos(Theta);
    Y2d = Rmat.*sin(Theta);

    % Surface Geometry
    %H = 269e-6*ones(Nr+1,Nth+1);
    %H=(1.011*pi/180)*Rmat;
    %H=asym_H(14.25e-3,3e-3,5.3,Nr,269e-6);

    %h=zeros((Nr+1)*(Nth+1),1);
    %for j=1:Nth+1
    %    h(1+(j-1)*(Nr+1):(Nr+1)+(j-1)*(Nr+1))=H(:,j);
    %end
    h = reshape(H,numel(H),1);
    
    Dr2d=2/(ro-ri)*kron(Ith,Dr);
    Dth2d=2/phi*kron(Dth,Ir);
    dhdr=Dr2d*h;
    dhdth=Dth2d*h;

    z3d=kron((1+zz)/2,h);
    h3d=kron(ones(Nz+1,1),h);
    r3d=kron(ones(Nz+1,1),r2d);
    theta3d=kron(ones(Nz+1,1),theta2d);
    J3d=(J2d*h3d/2);
    w3d=kron(wz,kron(wth,wr));

    dcdr=2/(ro-ri)*ones((Nr+1)*(Nth+1)*(Nz+1),1); 
    dcdth=zeros((Nr+1)*(Nth+1)*(Nz+1),1); 
    dcdz=zeros((Nr+1)*(Nth+1)*(Nz+1),1);

    dsdr=zeros((Nr+1)*(Nth+1)*(Nz+1),1); 
    dsdth=2/phi*ones((Nr+1)*(Nth+1)*(Nz+1),1); 
    dsdz=zeros((Nr+1)*(Nth+1)*(Nz+1),1);

    dedr=kron(-(1+zz),(dhdr./h)); 
    dedth=kron(-(1+zz),(dhdth./h)); 
    dedz=2./h3d;

    G11=sparse(diag((dcdr.*r3d.*dcdr...
                    +dcdth.*(1./r3d).*dcdth...
                    +dcdz.*r3d.*dcdz).*(w3d.*J3d)));
    G12=sparse(diag((dcdr.*r3d.*dsdr...
                    +dcdth.*(1./r3d).*dsdth...
                    +dcdz.*r3d.*dsdz).*(w3d.*J3d)));
    G13=sparse(diag((dcdr.*r3d.*dedr...
                    +dcdth.*(1./r3d).*dedth...
                    +dcdz.*r3d.*dedz).*(w3d.*J3d)));
    G22=sparse(diag((dsdr.*r3d.*dsdr...
                    +dsdth.*(1./r3d).*dsdth...
                    +dsdz.*r3d.*dsdz).*(w3d.*J3d)));
    G23=sparse(diag((dsdr.*r3d.*dedr...
                    +dsdth.*(1./r3d).*dedth...
                    +dsdz.*r3d.*dsdz).*(w3d.*J3d)));
    G33=sparse(diag((dedr.*r3d.*dedr...
                    +dedth.*(1./r3d).*dedth...
                    +dedz.*r3d.*dedz).*(w3d.*J3d)));
    Gmat=sparse([G11,G12,G13;G12,G22,G23;G13,G23,G33]);
    Dc3d=kron(Iz,kron(Ith,Dr)); Ds3d=kron(Iz,kron(Dth,Ir)); 
    De3d=kron(Dz,kron(Ith,Ir));
    D3d=sparse([Dc3d;Ds3d;De3d]);
    Kb=sparse(D3d'*Gmat*D3d);
    M3d=sparse(diag(w3d.*J3d.*r3d));

    Kur=kron(Proz,kron(Qth,NuemrL))'*Kb*kron(Proz,kron(Qth,NuemrL));
    Mur=kron(Proz,kron(Qth,NuemrL))'*M3d*kron(Proz,kron(Qth,NuemrL));
    Kuth=kron(Proz,kron(Qth,Ir))'*Kb*kron(Proz,kron(Qth,Ir));
    Muth=kron(Proz,kron(Qth,Ir))'*M3d*kron(Proz,kron(Qth,Ir));
    Kuz=kron(Proz,kron(Qth,Ir))'*Kb*kron(Proz,kron(Qth,Ir));
    Muz=kron(Proz,kron(Qth,Ir))'*M3d*kron(Proz,kron(Qth,Ir));
    Kp=kron(Iz,kron(Qth,NuemrL))'*Kb*kron(Iz,kron(Qth,NuemrL));
    %Kp=kron(Iz,kron(Qth,Ir))'*Kb*kron(Iz,kron(Qth,Ir));
    Kt=kron(Iz,kron(Qth,Ir))'*Kb*kron(Iz,kron(Qth,Ir));
    Mt=kron(Iz,kron(Qth,Ir))'*M3d*kron(Iz,kron(Qth,Ir));

    Dr3d=sparse([diag(dcdr),diag(dsdr),diag(dedr)])*D3d;
    Dth3d=sparse([diag(dcdth),diag(dsdth),diag(dedth)])*D3d;
    Dz3d=sparse([diag(dcdz),diag(dsdz),diag(dedz)])*D3d;

    Drm3d=M3d*Dr3d; Dthm3d=M3d*Dth3d; Dzm3d=M3d*Dz3d;

    Urb=zeros((Nr+1)*(Nth+1)*(Nz+1),1);
    Uthb=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Uthb(1:(Nr+1)*(Nth+1))=r2d*Omega;
    Uzb=zeros((Nr+1)*(Nth+1)*(Nz+1),1);

    T=0.25; dt=7.12500e-05; nt=floor(T/dt); dt=T/nt;

    Ur=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Ur1=Ur; Ur2=Ur1; Ur3=Ur2;
    Uth=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Uth1=Uth; Uth2=Uth1; Uth3=Uth2;
    Uz=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Uz1=Uz; Uz2=Uz1; Uz3=Uz2;

    fUr=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fUr1=fUr; fUr2=fUr1; fUr3=fUr2;
    fUth=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fUth1=fUth; fUth2=fUth1; fUth3=fUth2;
    fUz=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fUz1=fUz; fUz2=fUz1; fUz3=fUz2;

    Trrt=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trrt1=Trrt; Trrt2=Trrt1; Trrt3=Trrt2;
    Trtt=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trtt1=Trtt; Trtt2=Trtt1; Trtt3=Trtt2;
    Trzt=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trzt1=Trzt; Trzt2=Trzt1; Trzt3=Trzt2;
    Tttt=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Tttt1=Tttt; Tttt2=Tttt1; Tttt3=Tttt2;
    Ttzt=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Ttzt1=Ttzt; Ttzt2=Ttzt1; Ttzt3=Ttzt2;
    Tzzt=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Tzzt1=Tzzt; Tzzt2=Tzzt1; Tzzt3=Tzzt2;

    Trr1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trr11=Trr1; Trr12=Trr11; Trr13=Trr12;
    Trt1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trt11=Trt1; Trt12=Trt11; Trt13=Trt12;
    Trz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trz11=Trz1; Trz12=Trz11; Trz13=Trz12;
    Ttt1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Ttt11=Ttt1; Ttt12=Ttt11; Ttt13=Ttt12;
    Ttz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Ttz11=Ttz1; Ttz12=Ttz11; Ttz13=Ttz12;
    Tzz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Tzz11=Tzz1; Tzz12=Tzz11; Tzz13=Tzz12;

    fTrr1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTrr11=fTrr1; fTrr12=fTrr11; fTrr13=fTrr12;
    fTrt1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTrt11=fTrt1; fTrt12=fTrt11; fTrt13=fTrt12;
    fTrz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTrz11=fTrz1; fTrz12=fTrz11; fTrz13=fTrz12;
    fTtt1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTtt11=fTtt1; fTtt12=fTtt11; fTtt13=fTtt12;
    fTtz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTtz11=fTtz1; fTtz12=fTtz11; fTtz13=fTtz12;
    fTzz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTzz11=fTzz1; fTzz12=fTzz11; fTzz13=fTzz12;

    fcTrr1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTrr11=fcTrr1; fcTrr12=fcTrr11; fcTrr13=fcTrr12;
    fcTrt1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTrt11=fcTrt1; fcTrt12=fcTrt11; fcTrt13=fcTrt12;
    fcTrz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTrz11=fcTrz1; fcTrz12=fcTrz11; fcTrz13=fcTrz12;
    fcTtt1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTtt11=fcTtt1; fcTtt12=fcTtt11; fcTtt13=fcTtt12;
    fcTtz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTtz11=fcTtz1; fcTtz12=fcTtz11; fcTtz13=fcTtz12;
    fcTzz1=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTzz11=fcTzz1; fcTzz12=fcTzz11; fcTzz13=fcTzz12;

    Trr2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trr21=Trr2; Trr22=Trr21; Trr23=Trr22;
    Trt2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trt21=Trt2; Trt22=Trt21; Trt23=Trt22;
    Trz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Trz21=Trz2; Trz22=Trz21; Trz23=Trz22;
    Ttt2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Ttt21=Ttt2; Ttt22=Ttt21; Ttt23=Ttt22;
    Ttz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Ttz21=Ttz2; Ttz22=Ttz21; Ttz23=Ttz22;
    Tzz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); Tzz21=Tzz2; Tzz22=Tzz21; Tzz23=Tzz22;

    fTrr2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTrr21=fTrr2; fTrr22=fTrr21; fTrr23=fTrr22;
    fTrt2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTrt21=fTrt2; fTrt22=fTrt21; fTrt23=fTrt22;
    fTrz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTrz21=fTrz2; fTrz22=fTrz21; fTrz23=fTrz22;
    fTtt2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTtt21=fTtt2; fTtt22=fTtt21; fTtt23=fTtt22;
    fTtz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTtz21=fTtz2; fTtz22=fTtz21; fTtz23=fTtz22;
    fTzz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fTzz21=fTzz2; fTzz22=fTzz21; fTzz23=fTzz22;

    fcTrr2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTrr21=fcTrr2; fcTrr22=fcTrr21; fcTrr23=fcTrr22;
    fcTrt2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTrt21=fcTrt2; fcTrt22=fcTrt21; fcTrt23=fcTrt22;
    fcTrz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTrz21=fcTrz2; fcTrz22=fcTrz21; fcTrz23=fcTrz22;
    fcTtt2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTtt21=fcTtt2; fcTtt22=fcTtt21; fcTtt23=fcTtt22;
    fcTtz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTtz21=fcTtz2; fcTtz22=fcTtz21; fcTtz23=fcTtz22;
    fcTzz2=zeros((Nr+1)*(Nth+1)*(Nz+1),1); fcTzz21=fcTzz2; fcTzz22=fcTzz21; fcTzz23=fcTzz22;


    for k=1:nt,
        t=dt*k;
        if k==1,   % BDF1/EXT1
            b0=1; b1=1; b2=0; b3=0; 
            e1=1; e2=0; e3=0; 
        end
        if k==2,% BDF2/EXT2
            b0=1.5; b1=2; b2=-.5; b3=0; 
            e1=2; e2=-1; e3=0; 
        end
        if k==3,   % BDF3/EXT3
            b0=11/6; b1=3; b2=-1.5; b3=1/3; 
            e1=3; e2=-3; e3=1; 
        end

        Ur3=Ur2; Ur2=Ur1; Ur1=Ur;
        Uth3=Uth2; Uth2=Uth1; Uth1=Uth;
        Uz3=Uz2; Uz2=Uz1; Uz1=Uz;

        Trrt3=Trrt2; Trrt2=Trrt1; Trrt1=Trrt;
        Trtt3=Trtt2; Trtt2=Trtt1; Trtt1=Trtt;
        Trzt3=Trzt2; Trzt2=Trzt1; Trzt1=Trzt;
        Tttt3=Tttt2; Tttt2=Tttt1; Tttt1=Tttt;
        Ttzt3=Ttzt2; Ttzt2=Ttzt1; Ttzt1=Ttzt;
        Tzzt3=Tzzt2; Tzzt2=Tzzt1; Tzzt1=Tzzt;

        Trr13=Trr12; Trr12=Trr11; Trr11=Trr1;
        Trt13=Trt12; Trt12=Trt11; Trt11=Trt1;
        Trz13=Trz12; Trz12=Trz11; Trz11=Trz1;
        Ttt13=Ttt12; Ttt12=Ttt11; Ttt11=Ttt1;
        Ttz13=Ttz12; Ttz12=Ttz11; Ttz11=Ttz1;
        Tzz13=Tzz12; Tzz12=Tzz11; Tzz11=Tzz1;

        Trr23=Trr22; Trr22=Trr21; Trr21=Trr2;
        Trt23=Trt22; Trt22=Trt21; Trt21=Trt2;
        Trz23=Trz22; Trz22=Trz21; Trz21=Trz2;
        Ttt23=Ttt22; Ttt22=Ttt21; Ttt21=Ttt2;
        Ttz23=Ttz22; Ttz22=Ttz21; Ttz21=Ttz2;
        Tzz23=Tzz22; Tzz22=Tzz21; Tzz21=Tzz2;

        Cr=sparse(diag(Ur))*Drm3d; 
        Cth=sparse(diag(Uth))*(sparse(diag(1./r3d)))*Dthm3d;
        Cz=sparse(diag(Uz))*Dzm3d;
        C=Cr+Cth+Cz;    

        fUr=-C*Ur+(M3d*sparse(diag(1./r3d)))*(Uth.^2);
        fUth=-C*Uth-(M3d*sparse(diag(1./r3d)))*(Uth.*Ur);
        fUz=-C*Uz;

        fTrr1=-C*Trr1+(M3d*sparse(diag(1./r3d)))*(Uth.*(Trt1+Trt1));
        fTrt1=-C*Trt1-(M3d*sparse(diag(1./r3d)))*(Uth.*(Trr1-Ttt1));
        fTrz1=-C*Trz1+(M3d*sparse(diag(1./r3d)))*(Uth.*(Ttz1));
        fTtt1=-C*Ttt1-(M3d*sparse(diag(1./r3d)))*(Uth.*(Trt1+Trt1));
        fTtz1=-C*Ttz1-(M3d*sparse(diag(1./r3d)))*(Uth.*(Trz1));
        fTzz1=-C*Tzz1;

        fTrr2=-C*Trr2+(M3d*sparse(diag(1./r3d)))*(Uth.*(Trt2+Trt2));
        fTrt2=-C*Trt2-(M3d*sparse(diag(1./r3d)))*(Uth.*(Trr2-Ttt2));
        fTrz2=-C*Trz2+(M3d*sparse(diag(1./r3d)))*(Uth.*(Ttz2));
        fTtt2=-C*Ttt2-(M3d*sparse(diag(1./r3d)))*(Uth.*(Trt2+Trt2));
        fTtz2=-C*Ttz2-(M3d*sparse(diag(1./r3d)))*(Uth.*(Trz2));
        fTzz2=-C*Tzz2;

        fcTrr1=2*(sparse(diag(Trr1))*(Drm3d*Ur)...
                +sparse(diag(Trt1))*(sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth))...
                +sparse(diag(Trz1))*(Dzm3d*Ur));
        fcTrt1=sparse(diag(Trr1))*(Drm3d*Uth)...
             +sparse(diag(Trt1))*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur)...
                                    +Drm3d*Ur)...
             +sparse(diag(Trz1))*(Dzm3d*Uth)...
             +sparse(diag(Ttz1))*(Dzm3d*Ur)...
             +sparse(diag(Ttt1))*(sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth));
        fcTrz1=sparse(diag(Trr1))*(Drm3d*Uz)...
             +sparse(diag(Trz1))*(Dzm3d*Uz+Drm3d*Ur)...
             +sparse(diag(Trt1))*(sparse(diag(1./r3d))*(Dthm3d*Uz))...
             +sparse(diag(Ttz1))*(sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth))...
             +sparse(diag(Tzz1))*(Dzm3d*Ur);
        fcTtt1=2*(sparse(diag(Trt1))*(Drm3d*Uth)...
                +sparse(diag(Ttt1))*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur))...
                +sparse(diag(Ttz1))*(Dzm3d*Uth));
        fcTtz1=sparse(diag(Trt1))*(Drm3d*Uz)...
             +sparse(diag(Ttz1))*(Dzm3d*Uz+...
                                   (sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur)))...
             +sparse(diag(Ttt1))*(sparse(diag(1./r3d))*(Dthm3d*Uz))...
             +sparse(diag(Trz1))*(Drm3d*Uth)...
             +sparse(diag(Tzz1))*(Dzm3d*Uth);
        fcTzz1=2*(sparse(diag(Trz1))*(Drm3d*Uz)...
                +sparse(diag(Ttz1))*(sparse(diag(1./r3d))*(Dthm3d*Uz))...
                +sparse(diag(Tzz1))*(Dzm3d*Uz));

        fcTrr2=2*(sparse(diag(Trr2))*(Drm3d*Ur)...
                +sparse(diag(Trt2))*(sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth))...
                +sparse(diag(Trz2))*(Dzm3d*Ur));
        fcTrt2=sparse(diag(Trr2))*(Drm3d*Uth)...
             +sparse(diag(Trt2))*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur)...
                                    +Drm3d*Ur)...
             +sparse(diag(Trz2))*(Dzm3d*Uth)...
             +sparse(diag(Ttz2))*(Dzm3d*Ur)...
             +sparse(diag(Ttt2))*(sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth));
        fcTrz2=sparse(diag(Trr2))*(Drm3d*Uz)...
             +sparse(diag(Trz2))*(Dzm3d*Uz+Drm3d*Ur)...
             +sparse(diag(Trt2))*(sparse(diag(1./r3d))*(Dthm3d*Uz))...
             +sparse(diag(Ttz2))*(sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth))...
             +sparse(diag(Tzz2))*(Dzm3d*Ur);
        fcTtt2=2*(sparse(diag(Trt2))*(Drm3d*Uth)...
                +sparse(diag(Ttt2))*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur))...
                +sparse(diag(Ttz2))*(Dzm3d*Uth));
        fcTtz2=sparse(diag(Trt2))*(Drm3d*Uz)...
             +sparse(diag(Ttz2))*(Dzm3d*Uz+...
                                   (sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur)))...
             +sparse(diag(Ttt2))*(sparse(diag(1./r3d))*(Dthm3d*Uz))...
             +sparse(diag(Trz2))*(Drm3d*Uth)...
             +sparse(diag(Tzz2))*(Dzm3d*Uth);
        fcTzz2=2*(sparse(diag(Trz2))*(Drm3d*Uz)...
                +sparse(diag(Ttz2))*(sparse(diag(1./r3d))*(Dthm3d*Uz))...
                +sparse(diag(Tzz2))*(Dzm3d*Uz));


        fTrr13=fTrr12; fTrr12=fTrr11; fTrr11=fTrr1;
        fTrt13=fTrt12; fTrt12=fTrt11; fTrt11=fTrt1;
        fTrz13=fTrz12; fTrz12=fTrz11; fTrz11=fTrz1;
        fTtt13=fTtt12; fTtt12=fTtt11; fTtt11=fTtt1;
        fTtz13=fTtz12; fTtz12=fTtz11; fTtz11=fTtz1;
        fTzz13=fTzz12; fTzz12=fTzz11; fTzz11=fTzz1;

        fcTrr13=fcTrr12; fcTrr12=fcTrr11; fcTrr11=fcTrr1;
        fcTrt13=fcTrt12; fcTrt12=fcTrt11; fcTrt11=fcTrt1;
        fcTrz13=fcTrz12; fcTrz12=fcTrz11; fcTrz11=fcTrz1;
        fcTtt13=fcTtt12; fcTtt12=fcTtt11; fcTtt11=fcTtt1;
        fcTtz13=fcTtz12; fcTtz12=fcTtz11; fcTtz11=fcTtz1;
        fcTzz13=fcTzz12; fcTzz12=fcTzz11; fcTzz11=fcTzz1;

        fTrr23=fTrr22; fTrr22=fTrr21; fTrr21=fTrr2;
        fTrt23=fTrt22; fTrt22=fTrt21; fTrt21=fTrt2;
        fTrz23=fTrz22; fTrz22=fTrz21; fTrz21=fTrz2;
        fTtt23=fTtt22; fTtt22=fTtt21; fTtt21=fTtt2;
        fTtz23=fTtz22; fTtz22=fTtz21; fTtz21=fTtz2;
        fTzz23=fTzz22; fTzz22=fTzz21; fTzz21=fTzz2;

        fcTrr23=fcTrr22; fcTrr22=fcTrr21; fcTrr21=fcTrr2;
        fcTrt23=fcTrt22; fcTrt22=fcTrt21; fcTrt21=fcTrt2;
        fcTrz23=fcTrz22; fcTrz22=fcTrz21; fcTrz21=fcTrz2;
        fcTtt23=fcTtt22; fcTtt22=fcTtt21; fcTtt21=fcTtt2;
        fcTtz23=fcTtz22; fcTtz22=fcTtz21; fcTtz21=fcTtz2;
        fcTzz23=fcTzz22; fcTzz22=fcTzz21; fcTzz21=fcTzz2;

        ftrr1=e1*fTrr11+e2*fTrr12+e3*fTrr13;
        ftrt1=e1*fTrt11+e2*fTrt12+e3*fTrt13;
        ftrz1=e1*fTrz11+e2*fTrz12+e3*fTrz13;
        fttt1=e1*fTtt11+e2*fTtt12+e3*fTtt13;
        fttz1=e1*fTtz11+e2*fTtz12+e3*fTtz13;
        ftzz1=e1*fTzz11+e2*fTzz12+e3*fTzz13;

        fctrr1=e1*fcTrr11+e2*fcTrr12+e3*fcTrr13;
        fctrt1=e1*fcTrt11+e2*fcTrt12+e3*fcTrt13;
        fctrz1=e1*fcTrz11+e2*fcTrz12+e3*fcTrz13;
        fcttt1=e1*fcTtt11+e2*fcTtt12+e3*fcTtt13;
        fcttz1=e1*fcTtz11+e2*fcTtz12+e3*fcTtz13;
        fctzz1=e1*fcTzz11+e2*fcTzz12+e3*fcTzz13;

        ftrr2=e1*fTrr21+e2*fTrr22+e3*fTrr23;
        ftrt2=e1*fTrt21+e2*fTrt22+e3*fTrt23;
        ftrz2=e1*fTrz21+e2*fTrz22+e3*fTrz23;
        fttt2=e1*fTtt21+e2*fTtt22+e3*fTtt23;
        fttz2=e1*fTtz21+e2*fTtz22+e3*fTtz23;
        ftzz2=e1*fTzz21+e2*fTzz22+e3*fTzz23;

        fctrr2=e1*fcTrr21+e2*fcTrr22+e3*fcTrr23;
        fctrt2=e1*fcTrt21+e2*fcTrt22+e3*fcTrt23;
        fctrz2=e1*fcTrz21+e2*fcTrz22+e3*fcTrz23;
        fcttt2=e1*fcTtt21+e2*fcTtt22+e3*fcTtt23;
        fcttz2=e1*fcTtz21+e2*fcTtz22+e3*fcTtz23;
        fctzz2=e1*fcTzz21+e2*fcTzz22+e3*fcTzz23;

        Trre1=b1*Trr11+b2*Trr12+b3*Trr13;
        Trte1=b1*Trt11+b2*Trt12+b3*Trt13;
        Trze1=b1*Trz11+b2*Trz12+b3*Trz13;
        Ttte1=b1*Ttt11+b2*Ttt12+b3*Ttt13;
        Ttze1=b1*Ttz11+b2*Ttz12+b3*Ttz13;
        Tzze1=b1*Tzz11+b2*Tzz12+b3*Tzz13;

        Trre2=b1*Trr21+b2*Trr22+b3*Trr23;
        Trte2=b1*Trt21+b2*Trt22+b3*Trt23;
        Trze2=b1*Trz21+b2*Trz22+b3*Trz23;
        Ttte2=b1*Ttt21+b2*Ttt22+b3*Ttt23;
        Ttze2=b1*Ttz21+b2*Ttz22+b3*Ttz23;
        Tzze2=b1*Tzz21+b2*Tzz22+b3*Tzz23;

        Trrs1=M3d*lambda1*Trre1+dt*lambda1*ftrr1+dt*lambda1*fctrr1...
                +2*dt*etap1*(Drm3d*Ur)...
                -dt*alpha1/G1*M3d*((e1*Trr11+e2*Trr12+e3*Trr13).*(e1*Trr11+e2*Trr12+e3*Trr13)...
                                +(e1*Trt11+e2*Trt12+e3*Trt13).*(e1*Trt11+e2*Trt12+e3*Trt13)...
                                +(e1*Trz11+e2*Trz12+e3*Trz13).*(e1*Trz11+e2*Trz12+e3*Trz13));
        Trts1=M3d*lambda1*Trte1+dt*lambda1*ftrt1+dt*lambda1*fctrt1...
                +dt*etap1*(Drm3d*Uth+sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth))...
                -dt*alpha1/G1*M3d*((e1*Trt11+e2*Trt12+e3*Trt13).*(e1*Trr11+e2*Trr12+e3*Trr13)...
                                +(e1*Trt11+e2*Trt12+e3*Trt13).*(e1*Ttt11+e2*Ttt12+e3*Ttt13)...
                                +(e1*Trz11+e2*Trz12+e3*Trz13).*(e1*Ttz11+e2*Ttz12+e3*Ttz13));
        Trzs1=M3d*lambda1*Trze1+dt*lambda1*ftrz1+dt*lambda1*fctrz1...
                +dt*etap1*(Drm3d*Uz+Dzm3d*Ur)...
                -dt*alpha1/G1*M3d*((e1*Trz11+e2*Trz12+e3*Trz13).*(e1*Trr11+e2*Trr12+e3*Trr13)...
                                +(e1*Trz11+e2*Trt12+e3*Trz13).*(e1*Tzz11+e2*Tzz12+e3*Tzz13)...
                                +(e1*Trt11+e2*Trt12+e3*Trt13).*(e1*Ttz11+e2*Ttz12+e3*Ttz13));
        Ttts1=M3d*lambda1*Ttte1+dt*lambda1*fttt1+dt*lambda1*fcttt1...
                +2*dt*etap1*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur))...
                -dt*alpha1/G1*M3d*((e1*Trt11+e2*Trt12+e3*Trt13).*(e1*Trt11+e2*Trt12+e3*Trt13)...
                                +(e1*Ttt11+e2*Ttt12+e3*Ttt13).*(e1*Ttt11+e2*Ttt12+e3*Ttt13)...
                                +(e1*Ttz11+e2*Ttz12+e3*Ttz13).*(e1*Ttz11+e2*Ttz12+e3*Ttz13));
        Ttzs1=M3d*lambda1*Ttze1+dt*lambda1*fttz1+dt*lambda1*fcttz1...
                +dt*etap1*(sparse(diag(1./r3d))*(Dthm3d*Uz)+Dzm3d*Uth)...
                -dt*alpha1/G1*M3d*((e1*Ttz11+e2*Ttz12+e3*Ttz13).*(e1*Tzz11+e2*Tzz12+e3*Tzz13)...
                                +(e1*Ttz11+e2*Ttz12+e3*Ttz13).*(e1*Ttt11+e2*Ttt12+e3*Ttt13)...
                                +(e1*Trt11+e2*Trt12+e3*Trt13).*(e1*Trz11+e2*Trz12+e3*Trz13));
        Tzzs1=M3d*lambda1*Tzze1+dt*lambda1*ftzz1+dt*lambda1*fctzz1...
                +2*dt*etap1*(Dzm3d*Uz)...
                -dt*alpha1/G1*M3d*((e1*Trz11+e2*Trz12+e3*Trz13).*(e1*Trz11+e2*Trz12+e3*Trz13)...
                                +(e1*Ttz11+e2*Ttz12+e3*Ttz13).*(e1*Ttz11+e2*Ttz12+e3*Ttz13)...
                                +(e1*Tzz11+e2*Tzz12+e3*Tzz13).*(e1*Tzz11+e2*Tzz12+e3*Tzz13));


        Trrs2=M3d*lambda2*Trre2+dt*lambda2*ftrr2+dt*lambda2*fctrr2...
                +2*dt*etap2*(Drm3d*Ur)...
                -dt*alpha2/G2*M3d*((e1*Trr21+e2*Trr22+e3*Trr23).*(e1*Trr21+e2*Trr22+e3*Trr23)...
                                +(e1*Trt21+e2*Trt22+e3*Trt23).*(e1*Trt21+e2*Trt22+e3*Trt23)...
                                +(e1*Trz21+e2*Trz22+e3*Trz23).*(e1*Trz21+e2*Trz22+e3*Trz23));
        Trts2=M3d*lambda2*Trte2+dt*lambda2*ftrt2+dt*lambda2*fctrt2...
                +dt*etap2*(Drm3d*Uth+sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth))...
                -dt*alpha2/G2*M3d*((e1*Trt21+e2*Trt22+e3*Trt23).*(e1*Trr21+e2*Trr22+e3*Trr23)...
                                +(e1*Trt21+e2*Trt22+e3*Trt23).*(e1*Ttt21+e2*Ttt22+e3*Ttt23)...
                                +(e1*Trz21+e2*Trz22+e3*Trz23).*(e1*Ttz21+e2*Ttz22+e3*Ttz23));
        Trzs2=M3d*lambda2*Trze2+dt*lambda2*ftrz2+dt*lambda2*fctrz2...
                +dt*etap2*(Drm3d*Uz+Dzm3d*Ur)...
                -dt*alpha2/G2*M3d*((e1*Trz21+e2*Trz22+e3*Trz23).*(e1*Trr21+e2*Trr22+e3*Trr23)...
                                +(e1*Trz21+e2*Trt22+e3*Trz23).*(e1*Tzz21+e2*Tzz22+e3*Tzz23)...
                                +(e1*Trt21+e2*Trt22+e3*Trt23).*(e1*Ttz21+e2*Ttz22+e3*Ttz23));
        Ttts2=M3d*lambda2*Ttte2+dt*lambda2*fttt2+dt*lambda2*fcttt2...
                +2*dt*etap2*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur))...
                -dt*alpha2/G2*M3d*((e1*Trt21+e2*Trt22+e3*Trt23).*(e1*Trt21+e2*Trt22+e3*Trt23)...
                                +(e1*Ttt21+e2*Ttt22+e3*Ttt23).*(e1*Ttt21+e2*Ttt22+e3*Ttt23)...
                                +(e1*Ttz21+e2*Ttz22+e3*Ttz23).*(e1*Ttz21+e2*Ttz22+e3*Ttz23));
        Ttzs2=M3d*lambda2*Ttze2+dt*lambda2*fttz2+dt*lambda2*fcttz2...
                +dt*etap2*(sparse(diag(1./r3d))*(Dthm3d*Uz)+Dzm3d*Uth)...
                -dt*alpha2/G2*M3d*((e1*Ttz21+e2*Ttz22+e3*Ttz23).*(e1*Tzz21+e2*Tzz22+e3*Tzz23)...
                                +(e1*Ttz21+e2*Ttz22+e3*Ttz23).*(e1*Ttt21+e2*Ttt22+e3*Ttt23)...
                                +(e1*Trt21+e2*Trt22+e3*Trt23).*(e1*Trz21+e2*Trz22+e3*Trz23));
        Tzzs2=M3d*lambda2*Tzze2+dt*lambda2*ftzz2+dt*lambda2*fctzz2...
                +2*dt*etap2*(Dzm3d*Uz)...
                -dt*alpha2/G2*M3d*((e1*Trz21+e2*Trz22+e3*Trz23).*(e1*Trz21+e2*Trz22+e3*Trz23)...
                                +(e1*Ttz21+e2*Ttz22+e3*Ttz23).*(e1*Ttz21+e2*Ttz22+e3*Ttz23)...
                                +(e1*Tzz21+e2*Tzz22+e3*Tzz23).*(e1*Tzz21+e2*Tzz22+e3*Tzz23));

        %{                    
        Trrs2=M3d*lambda*Trre+dt*lambda*ftrr+dt*lambda*fctrr...
             +dt*lambda*((e1*Trr1+e2*Trr2+e3*Trr3)+etap/lambda).*fz...
             +dt*2*etap*(Drm3d*Ur);   
        Ttts2=M3d*lambda*Ttte+dt*lambda*fttt+dt*lambda*fcttt...
             +dt*lambda*((e1*Ttt1+e2*Ttt2+e3*Ttt3)+etap/lambda).*fz...
             +dt*2*etap*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur)); 
        Tzzs2=M3d*lambda*Tzze+dt*lambda*ftzz+dt*lambda*fctzz...
             +dt*lambda*((e1*Tzz1+e2*Tzz2+e3*Tzz3)+etap/lambda).*fz...
             +dt*2*etap*(Dzm3d*Uz);
        Trzs2=M3d*lambda*Trze+dt*lambda*ftrz+dt*lambda*fctrz...
             +dt*lambda*((e1*Trz1+e2*Trz2+e3*Trz3)).*fz...
             +dt*etap*(Drm3d*Uz+Dzm3d*Ur); 
        Trts2=M3d*lambda*Trte+dt*lambda*ftrt+dt*lambda*fctrt...
             +dt*lambda*((e1*Trt1+e2*Trt2+e3*Trt3)).*fz...
             +dt*etap*(Drm3d*Uth+sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth));
        Ttzs2=M3d*lambda*Ttze+dt*lambda*fttz+dt*lambda*fcttz...
             +dt*lambda*((e1*Ttz1+e2*Ttz2+e3*Ttz3)).*fz...
             +dt*etap*(sparse(diag(1./r3d))*(Dthm3d*Uz)+Dzm3d*Uth); 

        %}

        %{
        Trrs2=M3d*lambda*Trre+dt*lambda*ftrr+dt*lambda*fctrr...
             +dt*lambda*((e1*Trr1+e2*Trr2+e3*Trr3)+(1+epsilon*b)*etap/lambda).*fz...
             +dt*2*(1+epsilon*b)*etap*(Drm3d*Ur);   
        Ttts2=M3d*lambda*Ttte+dt*lambda*fttt+dt*lambda*fcttt...
             +dt*lambda*((e1*Ttt1+e2*Ttt2+e3*Ttt3)+(1+epsilon*b)*etap/lambda).*fz...
             +dt*2*(1+epsilon*b)*etap*(sparse(diag(1./r3d))*(Dthm3d*Uth+M3d*Ur)); 
        Tzzs2=M3d*lambda*Tzze+dt*lambda*ftzz+dt*lambda*fctzz...
             +dt*lambda*((e1*Tzz1+e2*Tzz2+e3*Tzz3)+(1+epsilon*b)*etap/lambda).*fz...
             +dt*2*(1+epsilon*b)*etap*(Dzm3d*Uz);
        Trzs2=M3d*lambda*Trze+dt*lambda*ftrz+dt*lambda*fctrz...
             +dt*lambda*((e1*Trz1+e2*Trz2+e3*Trz3)).*fz...
             +dt*(1+epsilon*b)*etap*(Drm3d*Uz+Dzm3d*Ur); 
        Trts2=M3d*lambda*Trte+dt*lambda*ftrt+dt*lambda*fctrt...
             +dt*lambda*((e1*Trt1+e2*Trt2+e3*Trt3)).*fz...
             +dt*(1+epsilon*b)*etap*(Drm3d*Uth+sparse(diag(1./r3d))*(Dthm3d*Ur-M3d*Uth));
        Ttzs2=M3d*lambda*Ttze+dt*lambda*fttz+dt*lambda*fcttz...
             +dt*lambda*((e1*Ttz1+e2*Ttz2+e3*Ttz3)).*fz...
             +dt*(1+epsilon*b)*etap*(sparse(diag(1./r3d))*(Dthm3d*Uz)+Dzm3d*Uth); 
        %}
        %
        Trr1a=((b0*lambda1+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Trrs1);      
        Trt1a=((b0*lambda1+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Trts1); 
        Trz1a=((b0*lambda1+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Trzs1); 
        Ttt1a=((b0*lambda1+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Ttts1); 
        Ttz1a=((b0*lambda1+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Ttzs1); 
        Tzz1a=((b0*lambda1+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Tzzs1);

        Trr2a=((b0*lambda2+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Trrs2);      
        Trt2a=((b0*lambda2+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Trts2); 
        Trz2a=((b0*lambda2+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Trzs2); 
        Ttt2a=((b0*lambda2+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Ttts2); 
        Ttz2a=((b0*lambda2+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Ttzs2); 
        Tzz2a=((b0*lambda2+dt)*Mt)\(kron(Iz,kron(Qth,Ir))'*Tzzs2);
        %}
        %{
        Trr=(b0*lambda*Mt+dt*Mz)\(kron(Iz,kron(Qth,Ir))'*Trrs2);      
        Trt=(b0*lambda*Mt+dt*Mz)\(kron(Iz,kron(Qth,Ir))'*Trts2); 
        Trz=(b0*lambda*Mt+dt*Mz)\(kron(Iz,kron(Qth,Ir))'*Trzs2); 
        Ttt=(b0*lambda*Mt+dt*Mz)\(kron(Iz,kron(Qth,Ir))'*Ttts2); 
        Ttz=(b0*lambda*Mt+dt*Mz)\(kron(Iz,kron(Qth,Ir))'*Ttzs2); 
        Tzz=(b0*lambda*Mt+dt*Mz)\(kron(Iz,kron(Qth,Ir))'*Tzzs2);
        %}
        %
        Trr1=kron(Iz,kron(Qth,Ir))*Trr1a;
        Trt1=kron(Iz,kron(Qth,Ir))*Trt1a;
        Trz1=kron(Iz,kron(Qth,Ir))*Trz1a;
        Ttt1=kron(Iz,kron(Qth,Ir))*Ttt1a;
        Ttz1=kron(Iz,kron(Qth,Ir))*Ttz1a;
        Tzz1=kron(Iz,kron(Qth,Ir))*Tzz1a;

        Trr2=kron(Iz,kron(Qth,Ir))*Trr2a;
        Trt2=kron(Iz,kron(Qth,Ir))*Trt2a;
        Trz2=kron(Iz,kron(Qth,Ir))*Trz2a;
        Ttt2=kron(Iz,kron(Qth,Ir))*Ttt2a;
        Ttz2=kron(Iz,kron(Qth,Ir))*Ttz2a;
        Tzz2=kron(Iz,kron(Qth,Ir))*Tzz2a;

        %}

        Trr=Trr1+Trr2; Trrt=Trr;
        Trt=Trt1+Trt2; Trtt=Trt;
        Trz=Trz1+Trz2; Trzt=Trz;
        Ttt=Ttt1+Ttt2; Tttt=Ttt;
        Ttz=Ttz1+Ttz2; Ttzt=Ttz;
        Tzz=Tzz1+Tzz2; Tzzt=Tzz;


        %}

        fUr3=fUr2; fUr2=fUr1; fUr1=fUr;
        fUth3=fUth2; fUth2=fUth1; fUth1=fUth;
        fUz3=fUz2; fUz2=fUz1; fUz1=fUz;

        Ure=b1*Ur1+b2*Ur2+b3*Ur3; fur=e1*fUr1+e2*fUr2+e3*fUr3;
        Uthe=b1*Uth1+b2*Uth2+b3*Uth3; futh=e1*fUth1+e2*fUth2+e3*fUth3;
        Uze=b1*Uz1+b2*Uz2+b3*Uz3; fuz=e1*fUz1+e2*fUz2+e3*fUz3;

        Urs=M3d*Ure+dt*fur-dt*(eta/rho)*Kb*Urb...
                          -dt*(eta/rho)*M3d*sparse(diag(1./r3d.^2))*Urb...
                          -dt*(eta/rho)*sparse(diag(2./r3d.^2))*...
                                (Dthm3d*(e1*Uth1+e2*Uth2+e3*Uth3))...
                          +dt/rho*sparse(diag(1./r3d))*(Drm3d*(r3d.*Trr)+Dthm3d*Trt)...
                          +dt/rho*Dzm3d*Trz...
                          -dt/rho*M3d*sparse(diag(1./r3d))*Ttt;
        Uths=M3d*Uthe+dt*futh-dt*(eta/rho)*Kb*Uthb...
                             -dt*(eta/rho)*M3d*sparse(diag(1./r3d.^2))*Uthb...
                             +dt*(eta/rho)*sparse(diag(2./r3d.^2))*...
                                (Dthm3d*(e1*Ur1+e2*Ur2+e3*Ur3))...
                             +dt/rho*sparse(diag(1./r3d.^2))*(Drm3d*(r3d.^2.*Trt))...
                                +dt/rho*sparse(diag(1./r3d))*(Dthm3d*Ttt)...
                                +dt/rho*Dzm3d*Ttz;
        Uzs=M3d*Uze+dt*fuz-dt*(eta/rho)*Kb*Uzb...
                   +dt/rho*sparse(diag(1./r3d))*(Drm3d*(r3d.*Trz)+Dthm3d*Ttz)...
                   +dt/rho*Dzm3d*Tzz;

        rr=Dr3d'*Urs; rth=(sparse(diag(1./r3d))*Dth3d)'*Uths; rz=Dz3d'*Uzs;
        rp=rho/dt*(rr+rth+rz);
        %{
        rr=Dr3d'*(rho*fur+sparse(diag(1./r3d))*(Drm3d*(r3d.*Trr)+Dthm3d*Trt)...
                                +Dzm3d*Trz-M3d*sparse(diag(1./r3d))*Ttt); 
        rth=(sparse(diag(1./r3d))*Dth3d)'*(rho*futh+sparse(diag(1./r3d.^2))*(Drm3d*(r3d.^2.*Trt))...
                                +sparse(diag(1./r3d))*(Dthm3d*Ttt)...
                                +Dzm3d*Ttz); 
        rz=Dz3d'*(rho*fuz+sparse(diag(1./r3d))*(Drm3d*(r3d.*Trz)+Dthm3d*Ttz)...
                                +Dzm3d*Tzz);
        rp=(rr+rth+rz);
        %}
        p=Kp\(kron(Iz,kron(Qth,NuemrL))'*rp);
        P=kron(Iz,kron(Qth,NuemrL))*p;
        %p=Kp\(kron(Iz,kron(Qth,Ir))'*rp);
        %P=kron(Iz,kron(Qth,Ir))*p;
        p0=P(1:(Nr+1)*(Nth+1));
        P0=zeros(Nr+1,Nth+1);
        for j=1:Nth+1,
            for i=1:Nr+1,
                P0(i,j)=p0(i+(j-1)*(Nr+1));
            end
        end
        Pr0=P0(Nr+1,:);
        Pref=-1/2*(wth'*Pr0');
        P=P+Pref;
        p0=p0+Pref;
        P0=P0+Pref;

        Urds=Urs-dt/rho*Drm3d*P;
        Uthds=Uths-dt/rho*(sparse(diag(1./r3d)))*Dthm3d*P;
        Uzds=Uzs-dt/rho*Dzm3d*P;

        ur=(b0*Mur+dt*(eta/rho)*Kur+dt*(eta/rho)*Mur)\(kron(Proz,kron(Qth,NuemrL))'*Urds);
        uth=(b0*Muth+dt*(eta/rho)*Kuth+dt*(eta/rho)*Muth)\(kron(Proz,kron(Qth,Ir))'*Uthds);
        uz=(b0*Muz+dt*(eta/rho)*Kuz)\(kron(Proz,kron(Qth,Ir))'*Uzds);

        Ur=kron(Proz,kron(Qth,NuemrL))*ur+Urb;
        Uth=kron(Proz,kron(Qth,Ir))*uth+Uthb;
        Uz=kron(Proz,kron(Qth,Ir))*uz+Uzb;

        dUrdt=(b0*Ur-(b1*Ur1+b2*Ur2+b3*Ur3))/dt;
        dUthdt=(b0*Uth-(b1*Uth1+b2*Uth2+b3*Uth3))/dt;
        dUzdt=(b0*Uz-(b1*Uz1+b2*Uz2+b3*Uz3))/dt;
        dTrrdt=(b0*Trrt-(b1*Trrt1+b2*Trrt2+b3*Trrt3))/dt;
        dTrtdt=(b0*Trtt-(b1*Trtt1+b2*Trtt2+b3*Trtt3))/dt;
        dTrzdt=(b0*Trzt-(b1*Trzt1+b2*Trzt2+b3*Trzt3))/dt;
        dTttdt=(b0*Tttt-(b1*Tttt1+b2*Tttt2+b3*Tttt3))/dt;
        dTtzdt=(b0*Ttzt-(b1*Ttzt1+b2*Ttzt2+b3*Ttzt3))/dt;
        dTzzdt=(b0*Tzzt-(b1*Tzzt1+b2*Tzzt2+b3*Tzzt3))/dt;

        %{
        if mod(k,40)==0,
            semilogy(t,max(abs(dUrdt)),'bo');
            hold on
            semilogy(t,max(abs(dUthdt)),'ro');
            semilogy(t,max(abs(dUzdt)),'ko');
            semilogy(t,max(abs(dTrrdt)),'bs');
            semilogy(t,max(abs(dTrtdt)),'rs');
            semilogy(t,max(abs(dTrzdt)),'ks');
            semilogy(t,max(abs(dTttdt)),'b*');
            semilogy(t,max(abs(dTtzdt)),'r*');
            semilogy(t,max(abs(dTzzdt)),'k*');
            title(['t=' num2str(t) 's,']);
            drawnow()
        %hold off
        end
        %}
        if max(abs([dUrdt,dUthdt,dUzdt,dTrrdt,dTrtdt,dTrzdt,dTttdt,dTtzdt,dTzzdt]))<1e-5,
            break;
        end

        %max(abs([dUrdt,dUthdt,dUzdt,dTrrdt,dTrtdt,dTrzdt,dTttdt,dTtzdt,dTzzdt]))<1e-6,


        %{
        figure()
        quiver3(r3d.*cos(theta3d),r3d.*sin(theta3d),z3d,...
               (Ur.*cos(theta3d)-Uth.*sin(theta3d)),...
               (Ur.*sin(theta3d)+Uth.*cos(theta3d)),Uz)
        title(['t=' num2str(t) 's,']);
        drawnow()
        %}

    end

    Tzth=eta*(Dz3d*Uth+sparse(diag(1./r3d))*Dth3d*Uz);
    Tzth0=Tzth(1:(Nr+1)*(Nth+1))+Ttz(1:(Nr+1)*(Nth+1));
    Tzzn=2*eta*(Dz3d*Uz);
    Tzz0=Tzzn(1:(Nr+1)*(Nth+1))+Tzz(1:(Nr+1)*(Nth+1));
    M=abs(Ntex*(w2d.*J2d)'*(sparse(diag(r2d.^2))*Tzth0));
    negFn=-Ntex*((w2d.*J2d)'*(sparse(diag(r2d))*(p0-Tzz0)));
    
end