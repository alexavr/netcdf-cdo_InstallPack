# netcdf-cdo_InstallPack


1. Clone
2. [Download](http://sail.ocean.ru/downloads/cdo_InstallPack.tar.gz) src files and unpack it in cdo_InstallPack directory
3. Make directory to install into
4. Create an install script (you may use examples from `./install_scripts/`) 
	1. Set `CDOPATHFLODER` variable as path to your installation dir 
	2. Set `CDONAME` variable as name of your installation dir 
	3. Comment/uncomment tar.gz package names in `TARLIST` (if needed)
		*If you just need netcdf -- stop on netcdf package*
		*The good idea would be to install packages one-by-one buy commenting and uncommenting thouse.*


