::#! 2> /dev/null                                             #
@ 2>/dev/null # 2>nul & echo off & goto BOF                   #
if [ -f "$0.com" ] && [ "$0.com" -nt "$0" ]; then             #
  exec "$0.com" "$@"                                          #
fi                                                            #
rm -f "$0.com"                                                #
if [ -z ${SIREUM_HOME} ]; then                                #
  echo "Please set SIREUM_HOME env var"                       #
  exit -1                                                     #
fi                                                            #
exec ${SIREUM_HOME}/bin/sireum slang run -n "$0" "$@"         #
:BOF
if not defined SIREUM_HOME (
  echo Please set SIREUM_HOME env var
  exit /B -1
)
%SIREUM_HOME%\bin\sireum.bat slang run -n "%0" %*
exit /B %errorlevel%
::!#
// #Sireum
import org.sireum._

val home = Os.slashDir
val sireum = home / "bin"/ "sireum"

val osateHome = Os.home / ".sireum" / "phantom" / "osate-2.9.2-vfinal" / "osate"
val phantomArgs = "-nosplash -console -consoleLog -data @user.home/.sireum -application org.sireum.aadl.osate.cli"

{ // install osate plugins via phantom
  proc"${sireum.string} hamr phantom -u".at(home).console.runCheck()
  assert(osateHome.exists, s"${osateHome} not found")
}

{
  println("Run HAMR on a sample AADL project ...")

  proc"wget --no-check-certificate https://github.com/santoslab/iccps20-case-studies/archive/master.tar.gz".at(home).runCheck()
  proc"tar xf master.tar.gz".at(home).console.runCheck()

  val aadlDir = home / "iccps20-case-studies-master" / "temperature-control" / "aadl"
  assert(aadlDir.exists, s"${aadlDir} missing")

  val codegenArgs = "hamr codegen --no-proyek-ive --output-dir slang"

  {
    println("Method 1: generate AIR, serialize to a file, pass that file to HAMR")
    proc"${sireum.string} hamr phantom ${aadlDir.string}".at(home).console.runCheck()

    val json = aadlDir / ".slang" / "TemperatureControl_TempControlSystem_i_Instance.json"
    assert(json.exists, s"${json} doesn't exist")

    proc"${sireum.string} ${codegenArgs} ${json}".at(home).console.runCheck()

    val slangDir = home / "slang"
    assert(slangDir.exists, s"${slangDir} doesn't exists")
    slangDir.removeAll()
  }

  println()

  {
    println("Method 2: use Sireum's OSATE CLI plugin to directly invoke HAMR via OSATE")

    proc"${osateHome.string} ${phantomArgs} ${codegenArgs} ${aadlDir.string}/.project".at(home).console.runCheck()
  }
}