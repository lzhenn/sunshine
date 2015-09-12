function sunshine()
while(1)
	clear all;
	close all;
	echo off;
	delay=0;
	cnow=clock();
	if(cnow(4)*100+cnow(5)<1830)	%execute time 18:30
		clc;
		delay=(18*3600+30*60-(cnow(4)*3600+cnow(5)*60+cnow(6)));
		fprintf(['Programm has been hold on wating for the next caculation\n\n NEXT CACULATING TIME: ',datestr(now+delay/86400),'\n']);
	pause(delay);
		cnow=clock();		%get time again
	end
	check_time=[num2str(cnow(1)),full(cnow(2)),full(cnow(3)),'0001'];
	



	JLday=timeget(check_time);
	
	Day_Rank=round(JLday-datenum(str2num(check_time(1:4)),1,1,0,0,0));
	mdayvec=load('parameter/midday.txt');
    if Day_Rank==0
        Day_Rank=1;
    end
	mday=mdayvec(Day_Rank);							%Get midday second of today
	
	fid1=fopen('parameter/sundata.txt','r');				
	for i=1:366
		sunline=fgetl(fid1);
		if sunline(1:2)==check_time(5:6)&sunline(4:5)==check_time(7:8)	%Get the right line of today
			break;
		end
	end
	fclose(fid1);

	srh=str2num(sunline(7:8));
	srm=str2num(sunline(10:11));
	ssh=str2num(sunline(13:14));
	ssm=str2num(sunline(16:17));

	if (str2num(check_time(5:6))>3)&(str2num(check_time(5:6))<10)	%Summer Time
		start_time=[full(srh+1),sunline(10:11)];
		end_time=[full(ssh-1),sunline(13:14)];
	else
		start_time=[full(srh+2),sunline(10:11)];
		end_time=[full(ssh-2),sunline(13:14)];
	end
	
	sr_s=srh*3600+srm*60;				%Get the seconds of sunrise to midnight	
	ss_s=ssh*3600+ssm*60;				%Get the seconds of sunset to midnight

	
	sunshine=0;			%successful and sun on
	successful_time=0;		%successfully read img number
	failed_time=0;			%faildly read img number
	series='';			%time series list 
	

	while(str2num(start_time)<=str2num(end_time))
		
		check_now_time=[check_time(1:8),start_time]; %e.g. '201302251123'
		
		start_time=timeadd(start_time);

		body_X=0;
		body_Y=0;

		%-----------IM reading and processing-----------
		disp(['Working on ',check_now_time]);

		JLday=timeget(check_now_time);
		[dnflag,sunh]=dayornight(check_now_time,JLday,mday);
		if (dnflag)
			continue;
		end

		try
			imgpath=['../../archive/cam8/',check_time(1:8),'/ch01_',check_now_time,'*.png'];
			file=dir(imgpath);
			imgname=['../../archive/cam8/',check_time(1:8),'/',file(1).name];
			I = imread(imgname);
		catch
			failed_time=failed_time+1;
			series=[series,sprintf([check_now_time,'%3d\n'],-1)];			
			continue;
		end
		
		successful_time=successful_time+1;
		I = I(1:576,1:704,:);		%cut the bottom timestamp line		
		I = imresize(I,[527 704]);	%Change the size of picture
		I=I(:,90:616,:);	%Cut out the interesting part
		I=rgb2gray(I);				%rgb2gray passage

		
				
		%-----------body search process-----------
		I=im2bw(I,0.98);
		search_r=round(262-sunh);
		try
			L=bwlabel(I);
			stats=regionprops(L,'Area');					%Get every labels' Area
			allArea=[stats.Area];				
			allArea=sort(allArea,'descend');
			len=length(allArea);
			if(max(allArea)>=400)
				idx=find([stats.Area]==max(allArea));			%Find the label which take the max area
			end

			s=regionprops(L,'centroid');					%Find every labels' Centroid
			centroids=cat(1,s.Centroid);
			if(round(sqrt((centroids(idx,1)-264)^2+(centroids(idx,2)-264)^2))<search_r)	%If not the light of Guangzhou or Lab, return celestial body result
				body_X=centroids(idx,1);
				body_Y=centroids(idx,2);
				sunshine=sunshine+1;
				series=[series,sprintf([check_now_time,'%3d\n'],1)];
			else
				series=[series,sprintf([check_now_time,'%3d\n'],0)];
				continue
			end
		catch
			series=[series,sprintf([check_now_time,'%3d\n'],0)];
			continue;
		end	
	end

	sunshine_per=sunshine/successful_time;
	pssd=(ss_s-sr_s)/3600;
	rssd=sunshine_per*(ss_s-sr_s)/3600;
	%------------------output-------------------
	
	%---------------text data---------------
	
	if(exist(['data/series/',check_time(1:4)])==0)		%If there is no such dir,make it
		mkdir('data/series/',check_time(1:4));	
	end
	
	fid1=fopen('realtime.txt','w');
	fprintf(fid1,[check_time(1:8),'%5d%5d%5d%8.2f%8.2f%5d\n'],successful_time,failed_time,sunshine,pssd,rssd,round(sunshine_per*100));
	fclose(fid1);
	
	fid2=fopen(['data/series/',check_time(1:4),'/',check_time(1:8),'.txt'],'w');
	fprintf(fid2,[check_time(1:8),'%5d%5d%5d%8.2f%8.2f%5d\n'],successful_time,failed_time,sunshine,pssd,rssd,round(sunshine_per*100));
	fprintf(fid2,'------------------------------------------------------------\n');	
	fprintf(fid2,series);
	fclose(fid2);
	
	%---------------graph data---------------
	if(exist(['data/track/',check_time(1:4)])==0)		%If there is no such dir,make it
		mkdir('data/track/',check_time(1:4));	
	end

	fid1=fopen(['data/series/',check_time(1:4),'/',check_time(1:8),'.txt'],'r');
	
	sunvec=zeros(840,1);
	picstat=zeros(840,1); %0 for okay,1 for ruined 
	str=fgetl(fid1);
	str=fgetl(fid1);
	str=fgetl(fid1);		%Preread
	pos=(str2num(str(9:10))*60-6*60)+str2num(str(11:12))+1;
	startpos=str(9:12);
	startposmin=(str2num(str(9:10))*60-6*60)+str2num(str(11:12))+1;
	while(~feof(fid1))
		str=fgetl(fid1);
		pos=pos+1;
		sunvec(pos,1)=str2num(str(14:15));
		if(sunvec(pos,1)<0) 
			sunvec(pos,1)=1;
			picstat(pos,1)=1;
		end
	end
	fclose(fid1);

	endpos=str(9:12);
	endposmin=(str2num(str(9:10))*60-6*60)+str2num(str(11:12))+1;
	len=endposmin-startposmin+1;
	figure('Visible','off');
	h=bar(sunvec(startposmin:endposmin,1),'stack');
	ch=get(h,'children');
	color_map=ones(len,3);
	for i=1:len
		if picstat(i+startposmin-1,1)==0
			color_map(i,:)=[0 0 1];
		else
			color_map(i,:)=[1 0 0];
		end
	end
	set(ch,'EdgeColor','none');
	set(ch,'FaceVertexCData',color_map);

	axis([0 len 0 1]);
	set(gca,'ytick',0:1:1,'yticklabel',{'',''});
	xlab=cell(floor(len/60)+1);
	for i =1:floor(len/60)+1
		xlab(i)={[full(str2num(startpos(1:2))+i-1),':',startpos(3:4)]};
	end
	set(gca,'xtick',1:60:len,'xticklabel',xlab);
	set(gcf,'unit','normalized','position',[0.2,0.2,0.64,0.12]);
	titleline=sprintf('DPS: %4.1fh  SD: %4.1fh  PS: %3d%%',pssd,rssd,round(sunshine_per*100));
	title(['Sunshine Timeseries (',check_time(1:4),'-',check_time(5:6),'-',check_time(7:8),' ',titleline,')']);
	set(get(gca,'title'),'FontSize',12);
	set(gcf,'PaperPositionMode','auto');	%Output with the same size of Screen
	saveas(gcf,['data/track/',check_time(1:4),'/',check_time(1:8),'.jpg'],'jpg');
	saveas(gcf,'../../www/html/img/sunshine.jpg','jpg');
	hold off;	
	close(gcf);
	%---------------screen data---------------
	clc;
	fprintf(['    ----------------------RESULT LIST----------------------\n']);
	fprintf(['\tCaculating Date:\t\t\t',check_time(1:8),'\n']);
	fprintf('\tPossiable Sunshine Duration:\t\t%6.2fh\n',pssd);
	fprintf('\tReal Sunshine Duration:\t\t\t%6.2fh\n',rssd);
	fprintf('\tPercentage of Sunshine Duration:\t%5.1f%%\n',sunshine_per*100);
	fprintf('\tValid Picture Number:\t\t\t%4d\n',successful_time);
	fprintf('\tRuined Picture Number:\t\t\t%4d\n',failed_time);
	fprintf(['    -------------------------------------------------------\n\n']);
	cnow=clock();
	delay=(86400-(cnow(4)*3600+cnow(5)*60+cnow(6)))+18*3600+30*60;
	fprintf(['Programm has been hold on wating for the next caculation\n\n NEXT CACULATING TIME: ',datestr(now+delay/86400),'\n']);
	pause(delay);
end		
%------------------------------Function TIMEGET()------------------------------
function JLday=timeget(filename)

	y=str2num(filename(1:4));
	m=str2num(filename(5:6));
	d=str2num(filename(7:8));
	h=str2num(filename(9:10));
	mn=str2num(filename(11:12));
	JLday=datenum(y,m,d,h,mn,0);

%------------------------------Function IFBODYHERE()------------------------------
function [dnflag,sunh,sunl]=dayornight(tstr,JLday,mday)
	dnflag=1;					%dnflag: 0 for day and 1 for night
	sunh=0;
	lon=113.39*pi/180;
	lat=23.05*pi/180;
	
	Day_Rank=round(JLday-datenum(str2num(tstr(1:4)),1,1,0,0,0));
	now_s=86400*(JLday-datenum(str2num(tstr(1:4)),str2num(tstr(5:6)),str2num(tstr(7:8)),0,0,0));
	Local_Time=now_s-mday;
	Hour_Angle=Local_Time*7.27e-5;
	Dec=asin(0.398*sin(4.87+0.0175*Day_Rank+0.033*sin(0.0175*Day_Rank)));
	sunh=asin(sin(lat)*sin(Dec)+cos(lat)*cos(Dec)*cos(Hour_Angle));
	sunh=sunh*180/pi;
	if sunh>0
		dnflag=0;
	end
%---------------------------------Function TIMEADD()------------------------------------
function tstr=timeadd(timestr)	%e.g. timestr='0911'
	hh=str2num(timestr(1:2));	
	mm=str2num(timestr(3:4));
	mm=mm+1;
	if mm==60
		mm=0;
		hh=hh+1;	
	end
	tstr=[full(hh),full(mm)];


%---------------------------------Function FULL()------------------------------------
function str=full(x)

	if(x<10)
		str=['0',int2str(x)];	
	else	
		str=int2str(x);
	end
