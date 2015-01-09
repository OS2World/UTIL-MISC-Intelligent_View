/* Intelligent View */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

crlf             = '0D0A'x
program_date     = '23/11/03'
program_version  = '0.3'
program_name     = 'Intelligent View'
program_web_page = 'http://www.os2world.com/spc'
programmer_name  = 'Salvador Parra Camacho'
programmer_email = 'x3265340@fedro.ugr.es'

parse source . . prog_exe

parse arg arguments

view   = 'view.exe'
winhlp = ''
e      = 'e.exe'

arguments = strip(arguments,,'"')

etcPath  = VALUE('ETC',,OS2ENVIRONMENT)
homePath = VALUE('HOME',,OS2ENVIRONMENT)

if STREAM(etcPath||'\inview.cfg','C','QUERY EXISTS') <> '' then
   call _loadrexx etcPath||'\inview.cfg'

if STREAM(homePath||'\inview.cfg','C','QUERY EXISTS') <> '' then
   call _loadrexx homePath||'\inview.cfg'

if STREAM(etcPath||'\inview.cfg','C','QUERY EXISTS') = '' &,
   STREAM(homePath||'\inview.cfg','C','QUERY EXISTS') = '' &,
   STREAM(exePath||'\inview.cfg','C','QUERY EXISTS') <> '' then
   call _loadrexx exePath||'\inview.cfg'

uls_path = value('ULSPATH',,OS2ENVIRONMENT)
lang     = substr(value('LANG',,OS2ENVIRONMENT),1,2)
prog_dir = delstr(prog_exe,lastpos('\',prog_exe))

call _defaultlanguage

if stream(uls_path||'\'||lang||'\inview.lng','C','QUERY EXISTS') <> '' then
	call _loadrexx uls_path||'\'||lang||'\inview.lng'
else
	do
	if stream(prog_dir||'\language\'||lang||'\inview.lng','C','QUERY EXISTS') <> '' then
	call _loadrexx prog_dir||'\language\'||lang||'\inview.lng'
	end

select
	when arguments = '' then
		call _view
	when arguments = '/I' then
		call _install
	when arguments = '/U' then
		call _uninstall
	when arguments = '/V' then
		call _version
	when arguments = '/S' then
		call _shadow
	when arguments = '/?' then
		call _help
	otherwise
		call _analyze
end

exit

_analyze:

if SysSearchPath('PATH','pe.exe') <> '' &,
   SysSearchPath('PATH','winhlp32.exe') <> '' &,
   winhlp = '' then
	winhlp = '@start /N pe.exe winhlp32.exe'
else
	if winhlp = '' then
		winhlp = '@start /WIN winhelp.exe'

rc = SysFileTree(arguments,stem,'FO')

if stem.0 = 0 then
	do
	'@start /N '||view||' '||arguments
	return
	end

file = stem.1

cars = chars(file)

if cars < 5 then
	file_contents = charin(file,1,cars)
else
	file_contents = charin(file,1,5)

call charout file

select
	when delstr(file_contents,6) = x2c('485350019B') then /* OS/2 INF */
		'@start /N '||view||' '||file
	when delstr(file_contents,6) = x2c('485350109B') then /* OS/2 HLP */
		'@start /N '||view||' '||file
	when delstr(file_contents,5) = x2c('3F5F0300') then /* Win HLP */
		winhlp||' '||file
	otherwise
		'@start /N '||e||' '||file
end
return

_install:

action = RxMessageBox(_Install,program_name,'OKCANCEL','NONE')

if action = 2 then return

if SysSetObjectData('<WP_VIEWINF>','EXENAME='||translate(prog_exe)) <> 1 then
	do
	call RxMessageBox _Error_installing,program_name,'OK','ERROR'
	return
	end

call RxMessageBox _Installed,program_name,'OK','NONE'

return

_uninstall:

action = RxMessageBox(_Uninstall,program_name,'OKCANCEL','NONE')

if action = 2 then return

if SysSetObjectData('<WP_VIEWINF>','EXENAME='||view||'') <> 1 then
	do
	call RxMessageBox _Error_uninstalling,program_name,'OK','ERROR'
	return
	end

call RxMessageBox _Uninstalled,program_name,'OK','NONE'

return

_version:

info_string = program_name||' '||program_version,
			crlf||program_date,
			crlf||program_web_page,
			crlf||programmer_name,
			crlf||programmer_email

call RxMessageBox info_string,program_name,'OK','NONE'

return

_help:

call RxMessageBox _Help,program_name,'OK','NONE'

return

_view:

'@start /N '||view||''

return

_shadow:

action = RxMessageBox(_Shadowing,program_name,'OKCANCEL','NONE')

if action = 2 then return

if SysCreateShadow('<WP_VIEWINF>','<WP_DESKTOP>') <> 1 then
	do
	call RxMessageBox _Error_shadowing,program_name,'OK','ERROR'
	return
	end

call RxMessageBox _Shadowed,program_name,'OK','NONE'

return

_defaultlanguage:

_Install            = " Installing Intelligent View in your system.",
                      " Do you want continue?"
_Error_installing   = " An error has ocurred installing Intelligent View!"
_Installed          = " Intelligent View successfully installed."
_Uninstall          = " Un-installing Intelligent View.",
                      " Do you want continue?"
_Error_uninstalling = " An error has ocurred un-installing Intelligent View!"
_Uninstalled        = " Intelligent View successfully un-installed."
_Help               = "Commandline options:",
                      crlf||" /V shows the version",
                      crlf||" /I installs the program",
                      crlf||" /U uninstalls the program",
                      crlf||" /S creates a shadow in the Desktop",
                      crlf||" /? shows this help"
_Shadowing          = " Creating a shadow of your View object in your",
                      " Desktop. Do you want continue?"
_Error_shadowing    = " An error ocurred creating shadow."
_Shadowed           = " Shadow successfully created."

return

_loadrexx:

parse arg RexxFile

RexxData = charin(RexxFile,1,chars(RexxFile))
call STREAM RexxFile,'C','CLOSE'
RexxData = _change(RexxData,','||crlf,'||')
RexxData = _change(RexxData,crlf,';')
interpret RexxData
drop RexxData

return

/* Mike Cowlishaw's CHANGE.REX */

_change:
procedure
parse arg string,old,new
if old='' then return new||string
out=''
do while pos(old,string)<>0
	parse var string prefix (old) string
	out=out||prefix||new
	end
return out||string