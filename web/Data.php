<?php
$host = '127.0.0.1';
$db   = 'request';
$user = 'root';
$pass = '';
$charset = 'utf8mb4';

// Don't touch below here.
$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];
try {
     $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
     throw new \PDOException($e->getMessage(), (int)$e->getCode());
}


class Request{
	public $Id;
	public $PlayerName;
	public $Text;
	public $DateCreation;
	public $SteamId;

	public function GetCreationDate()//: string
	{
		return date("jS F Y", strtotime($this->DateCreation));
	}
}


$rows = $pdo->query("SELECT id Id, playername PlayerName, request `Text`, date_creation DateCreation, steamid SteamId FROM request")->fetchAll(PDO::FETCH_CLASS, Request::class);
$bgs = [
	"https://i.imgur.com/uBwedSp.jpg",
	"https://i.imgur.com/vWUfvio.jpg",
	"https://i.imgur.com/9iDHUnf.png",
	"https://i.imgur.com/0WUDPAM.jpg",
	"https://i.imgur.com/KSbLmlF.jpg",
	"https://i.imgur.com/gZ5exKv.jpg",
	"https://i.imgur.com/lDNCyCX.png",
	"https://i.imgur.com/IVapl1N.png",
	"https://i.imgur.com/A7aNBOM.png",
	"https://i.imgur.com/ydk728A.png",
	"https://i.imgur.com/jDUFpJB.png",
	"https://i.imgur.com/tPRKA50.png",
	"https://i.imgur.com/5ayTPQz.png"
];
?>
