function img=algtest()
	clear all;
	close all;
	echo off;
	impath='day_clr2.png';
	im0 = imread(impath);
	im0 = imresize(im0, [527 704]);					%Change the size of picture
	im0=im0(21:509,109:597,:);					%Cut out the interesting part

	img=rgb2gray(im0);
	imd=im2bw(img,0.95);
	imshow(imd);
	hold on;
	try
		L=bwlabel(imd);
		stats=regionprops(L,'Area');					%Get every labels' Area
		allArea=[stats.Area];						
		allArea=sort(allArea,'descend');
		len=length(allArea);
		if(max(allArea)>=225)
			idx=find([stats.Area]==max(allArea));			%Find the label which take the max area
		end

		s=regionprops(L,'centroid');					%Find every labels' Centroid
		centroids=cat(1,s.Centroid);
		if(round(sqrt((centroids(idx,1)-245)^2+(centroids(idx,2)-245)^2))<225)	%If not the light of Guangzhou or Lab, return celestial body result
			body_X=centroids(idx,1);
			body_Y=centroids(idx,2);
		end
		body_R=sqrt((body_X-245)^2+(body_Y-245)^2);
	catch
		return;
	end
	
	lon=113.5*pi/180;
	lat=23*pi/180;
	mday=[31 28 31 30 31 30 31 31 30 31 30 31];
	
	year=2013;
	mon=7;
	day=13;
	hour=12;
	min=27;
	HA=((hour+min/60)*15-300)*pi/180+lon;
	dn=sum(mday(1:mon-1))+day;
	theta0=(360*dn/365)*pi/180;
	delta=(0.006918-0.399912*cos(theta0)+0.070257*sin(theta0)-0.006758*cos(2*theta0)+0.000907*sin(2*theta0)-0.002697*cos(3*theta0)+0.00148*sin(3*theta0));
	h0=asin(sin(lat)*sin(delta)+cos(lat)*cos(delta)*cos(HA))*180/pi;
	R=-0.0185*h0^2-1.3805*h0+274;
	dir=acos(sin(delta)*cos(lat)-cos(HA)*cos(delta)*sin(lat)/cos(h0*pi/180))*180/pi;
	if HA>0
		dir=360-dir;
	end
	the_x=245-R*sin(dir*pi/180);
	the_y=245-R*cos(dir*pi/180);
	
	plot(body_X,body_Y,'*',the_x,the_y,'+');
