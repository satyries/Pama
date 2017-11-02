<?php
parse_str($_SERVER['QUERY_STRING']);
$check_do= isset($do);
$check_name= isset($name);
$check_players=isset($players);
if ($check_do == false){//check if the "do=" request is missing: this thing ends now.
	exit();
}
if ($do == "register"){
	if ($check_name == false){
		exit();
	}else{
		if ($check_players == false){$players = 0;}
		if ($players >5){$players = 4;}
		$srv_name=$name;
		$ip= $_SERVER['REMOTE_ADDR'];
		$ut=time();
		print("players ".$players);
		$db=json_decode(db_load(),true);
		$store_server = array(
			array("ip" => $ip,
				"name" => $srv_name,
				"ut" => $ut,
				"players" => $players
			)
		);

		for($i = 0; $i < count($db); ++$i) {
			print("<br>doing...");
//			if (($ut-$db[$i]["ut"]) > 1000 ) {//this one is too old
//				print("too old");
//				continue;
//			}
			if ($ip == $db[$i]["ip"]){//this one it's me!
				print("<br>".$ip." on ".$db[$i]["ip"]."<br>");

				continue;
				}
			print("<br>time now: ".$ut);
			print("<br>time then: ".$db[$i]["ut"]);
			print("<br>age: ".($ut-$db[$i]["ut"])."<br>");
			$store_server[] = $db[$i];
		}

		db_write($store_server);


		}



	}
	elseif ($do == "lists"){
		print( file_get_contents('database.json', true));
		}
	elseif ($do == "ingame"){//the server is ingame, remove from ms list
		$db=json_decode(db_load(),true);
		$store_server = array();
		for($i = 0; $i < count($db); ++$i) {
			if ($ip == $db[$i]["ip"]){continue;}
			$store_server[] = $db[$i];
			}
		db_write($store_server);
	}
 else { 
	exit();
}

function db_load() {
//	return file_get_contents("database.json");
	print("giving the sample");
	return file_get_contents("sample.json");
} 

function db_write($data) {
	$fp = fopen('database.json', 'w');
	fwrite($fp, json_encode($data));
	fclose($fp);
} 



?>