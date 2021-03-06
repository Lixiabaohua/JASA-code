function [const,Pbeta,Pnbeta,mybic]= tune_StageII(Palp,k,m,mu,sampleX,y,bound,p,delta)
%choose tuning parameter in stage II and get penalized estimation of
%parameter notes: 
%Palp: penalized estimation of varying-coefficient function
%mu: tuning parameter in Stage II estimation
%sampleX: covariates sample
%k: knots for additive function
T=length(y);
%additive function B-spline
[Bx1,DBx1] = rspline2(sampleX(:,1), sampleX(:,1),m,k); %Step III
[Bx2,DBx2] = rspline2(sampleX(:,2), sampleX(:,2),m,k); %Step III
[Bx3,DBx3] = rspline2(sampleX(:,3), sampleX(:,3),m,k); %Step III
%weight matrix in stage II model identification
V1 =  (DBx1)'*DBx1/T;  V2 =  (DBx2)'*DBx2/T; V3 =  (DBx3)'*DBx3/T; 
%substuting into penalized varying-coefficient estimation
Py = y - Palp(:,1);
SP1 = (kron(Palp(:,2), ones(1,size(Bx1,2)))) .* Bx1;
SP2 = (kron(Palp(:,3), ones(1,size(Bx2,2)))) .* Bx2;
SP3 = (kron(Palp(:,4), ones(1,size(Bx3,2)))) .* Bx3;
SP=[SP1 SP2 SP3];
Pcoeff2 = pinv((SP)'*SP+delta * eye(size(SP,2)))*(SP)'*Py; 
diff2 = 1; coeff2 = Pcoeff2;
Omega2 = zeros(size(SP,2));
while (diff2>bound)
 coefind1 = coeff2(1:size(Bx1,2));
 coefind2 = coeff2((size(Bx1,2)+1):2*size(Bx1,2));
 coefind3 = coeff2((2*size(Bx1,2)+1):3*size(Bx1,2));
 nbeta1 =  sqrt(abs(coefind1'*V1*coefind1));
 nbeta2 =  sqrt(abs(coefind2'*V2*coefind2));
 nbeta3 =  sqrt(abs(coefind3'*V3*coefind3));
 constbeta1 = deriveSCAD(k^(-3/2)*nbeta1,mu)/nbeta1; 
 constbeta2 = deriveSCAD(k^(-3/2)*nbeta2,mu)/nbeta2; 
 constbeta3=   deriveSCAD(k^(-3/2)*nbeta3,mu)/nbeta3; 
 Omega2(1:size(Bx1,2),1:size(Bx1,2))= constbeta1*V1;
 Omega2((size(Bx1,2)+1):2*size(Bx1,2),(size(Bx1,2)+1):2*size(Bx1,2))= constbeta2*V2;
 Omega2((2*size(Bx1,2)+1): 3*size(Bx1,2),(2*size(Bx1,2)+1): 3*size(Bx1,2)) = constbeta3*V3;
 tem = pinv((SP)'*SP+T*Omega2+delta*eye(size(SP,2)))*(SP)'*Py;
 diff2 = norm(tem-coeff2);
 coeff2 = tem; 
end
 %penalized estimation of additive function \beta_{k}
coefind1 = coeff2(1:size(Bx1,2));
coefind2 = coeff2((size(Bx1,2)+1):2*size(Bx1,2));
coefind3 = coeff2((2*size(Bx1,2)+1):3*size(Bx1,2));
Pbeta1 = Bx1 * coefind1;
Pbeta2 = Bx2 * coefind2;
Pbeta3 = Bx3 * coefind3;
Pbeta = [Pbeta1 Pbeta2 Pbeta3];
c = mean(Pbeta);
Pbeta = Pbeta - repmat(c,T,1);
const = Palp(:,1) + Palp(:,2)*c(1)+Palp(:,3)*c(2)+Palp(:,4)*c(3);
%norm of second derivative of estimated \beta_{k} function
Pnbeta1 =  sqrt(abs(coefind1'*V1*coefind1));
Pnbeta2 =  sqrt(abs(coefind2'*V2*coefind2));
Pnbeta3 =  sqrt(abs(coefind3'*V3*coefind3));
Pnbeta = [Pnbeta1 Pnbeta2 Pnbeta3];
Ind = find(Pnbeta<bound);   %varying-coefficient term index
varyterm = length(Ind);
fit = const+ Palp(:,2).*Pbeta(:,1)+Palp(:,3).*Pbeta(:,2) + Palp(:,4).*Pbeta(:,3);
rss2 = sum((y- fit ).^2);    
mybic = log(rss2)+(varyterm + (p-varyterm)*(m+k))* log(T)/T;
end

