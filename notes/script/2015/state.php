<?php
header("Content-Type: text/html;charset=utf-8");
echo "<head><title>HOMED监控</title></head>";

echo "<table><tr><td><h1>MYSQl 主从同步状态</h1></td></tr>";
echo "<tr><td><pre>";
$tt=time();
$filelog="result_".$tt.".log";
$cmd="./getsqlstatus.sh >$filelog";
exec("sudo $cmd",$result);
$log=file_get_contents("$filelog");
echo "$log";

echo "</pre></td></tr>";
echo "</table>";
echo "<hr>";
echo "<br/>";
$result = @unlink($filelog);

echo "<table><tr><td><h1>集群服务状态</h1></td></tr>";
$filelog="rehomed_".$tt.".log";
$cmd="./gethomedstatus.sh >$filelog";
exec("sudo $cmd",$result);
$log="";
//$t1=time();
//while (time()-$t1<50) {
$log=file_get_contents("$filelog");
//if (strlen($log)>0)
//break;
//}
echo "<pre>$log</pre>";
echo "<tr><td><br/></td></tr></table>";


$result = @unlink($filelog);

?>
