a,b=sqrt(-9)
? "root -9 is ", a,":",b
rad = 0
unit = pi / 6
do 
	c=sin(rad)
	? "sin(",rad / pi,"*pi) is ",c
	c=cos(rad)
	? "cos(",rad / pi,"*pi) is ",c
	c=tan(rad)
	? "tan(",rad / pi,"*pi) is ",c
	rad+=unit
while (rad <= pi)
d=20 * log10(0.3)
? "0.3V is ",d,"dBV"
