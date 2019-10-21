<?php
require_once(__DIR__ . DIRECTORY_SEPARATOR . "Data.php");
?>

<!DOCTYPE html>

<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Requests</title>
    <meta name="description" content="">
    <meta name="keywords" content="">
    <meta name="author" content="">

    <!-- Font Awesome if you need it
	<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css">
	-->
    <link href="https://unpkg.com/tailwindcss@^1.0/dist/tailwind.min.css" rel="stylesheet">
    <!--Replace with your tailwind.css once created-->

    <link href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:400,700" rel="stylesheet">
    <style type="text/css">
    	.b{
    		background-color: #ffffff;
			background-image: url("data:image/svg+xml,%3Csvg width='52' height='26' viewBox='0 0 52 26' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffe4e0' fill-opacity='1'%3E%3Cpath d='M10 10c0-2.21-1.79-4-4-4-3.314 0-6-2.686-6-6h2c0 2.21 1.79 4 4 4 3.314 0 6 2.686 6 6 0 2.21 1.79 4 4 4 3.314 0 6 2.686 6 6 0 2.21 1.79 4 4 4v2c-3.314 0-6-2.686-6-6 0-2.21-1.79-4-4-4-3.314 0-6-2.686-6-6zm25.464-1.95l8.486 8.486-1.414 1.414-8.486-8.486 1.414-1.414z' /%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
    	}
    	.img-container{
    		height: 100px;
            overflow: hidden;
    	}
    </style>
</head>

<body class="b leading-normal tracking-normal" style="font-family: 'Source Sans Pro', sans-serif;">
    <section class="py-8">
        <div class="container flex flex-wrap mx-auto overflow-hidden">
            <div class="container mx-auto flex flex-wrap pt-4 pb-12">
                <h1 class="w-full my-2 text-5xl font-bold leading-tight text-center text-gray-800">Requests</h1>
                <div class="w-full mb-4">
                    <div class="h-1 mx-auto gradient w-64 opacity-25 my-0 py-0 rounded-t"></div>
                </div>

                <div class="flex flex-wrap -mx-2 overflow-hidden">
                </div>
            </div>
            <?php if(!sizeof($rows)): ?>
        		No requests, yet.
        	<?php else: ?>
		    	<?php foreach($rows as $row): ?>
		        <div class="my-2 px-2 w-full md:w-1/2 lg:w-1/3 mx-auto">
		            <div class="bg-white max-w-sm rounded overflow-hidden shadow-lg">
		                <div class="w-full img-container">
                            <img src="<?= $bgs[mt_rand(0, 12)] ?>">
                        </div>
		                <div class="px-6 py-4">
		                    <div class="font-bold text-xl mb-2"><?= $row->PlayerName ?> <sup> / <?= $row->SteamId ?></sup></div>
		                    <p class="text-gray-700 text-base">
		                    	<?= $row->Text ?>
		                    </p>
		                </div>
		                <div class="px-6 py-4">
		                    <span class="inline-block bg-gray-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 mr-2">
		                    	<?= $row->GetCreationDate() ?>
		                    </span>
		                </div>
		            </div>
		        </div>
		        <?php endforeach; ?>
	        <?php endif; ?>
        </div>
    </section>

    <footer>
    	<div class="container mx-auto p-4 mb-2 text-center shadow-lg bg-white">
    		Made by 
    		<a href="https://github.com/Arkarr" class="no-underline hover:shadow-lg text-blue-600 hover:text-blue-900">Arkarr</a> & 
    		<a href="https://github.com/Hackmastr" class="no-underline hover:shadow-lg text-blue-600 hover:text-blue-900">Hackmastr</a>
    	</div>
    </footer>

</body>

</html>