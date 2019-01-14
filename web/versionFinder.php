<?php
$servername = "hallddb";
$username = "vsuser";
$password = "";
$dbname = "vsdb";
//echo $_GET['qs'] . " ---> " . $_GET['qe'];
// Create connection
$conn = mysqli_connect($servername, $username, $password, $dbname);
// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

if( $_GET["recon_ver"] == "unknown")
{
    $sql="SELECT DISTINCT version FROM version WHERE packageID in (SELECT id from package where name=\"halld_recon\") && versionSetId in (SELECT DISTINCT versionSetId from version where packageID in (SELECT id from package where name=\"halld_sim\") ) && versionSetID in (SELECT id from versionSet where onOasis=1);";
}
else if( $_GET["sim_ver"] == "unknown")
{
    $sql="SELECT DISTINCT version from version where packageID in (SELECT id from package where name=\"halld_sim\") && versionSetID IN (SELECT DISTINCT versionSetId from version where packageId in (SELECT id from package where name=\"halld_recon\") && version=\"" . $_GET["recon_ver"] . "\") && versionSetID in (SELECT id from versionSet where onOasis=1);";
}
else
{
    $sqlsub="SELECT DISTINCT versionSetID from version where versionSetID IN (SELECT DISTINCT versionSetId from version where packageId in (SELECT id from package where name=\"halld_recon\") && version=\"" . $_GET["recon_ver"] . "\")" . " && versionSetID IN (SELECT DISTINCT versionSetId from version where packageId in (SELECT id from package where name=\"halld_sim\") && versionSetID in (SELECT id from versionSet where onOasis=1) && version=\"" . $_GET["sim_ver"] . "\")";
    $sql="SELECT filename as version,id as SetNum from versionSet where id in (" . $sqlsub . ");";
    //$sql="SELECT DISTINCT versionSetID from version where versionSetID IN (SELECT DISTINCT versionSetId from version where packageId=2 && version=\"" . $_GET["recon_ver"] . "\")" . " && versionSetID IN (SELECT DISTINCT versionSetId from version where packageId=3 && version=\"" . $_GET["sim_ver"] . "\");";
    //echo $sql;
}


$result = $conn->query($sql);
$data = array();
if ($result->num_rows > 0) {
// output data of each row
    while($row = $result->fetch_assoc()) {
        $data[]=$row;
     //echo "id: " . $row["id"]. " - Run: " . $row["run"]. "<br>";
    }
} 
$conn->close();

echo json_encode($data);
return json_encode($data);
?>
