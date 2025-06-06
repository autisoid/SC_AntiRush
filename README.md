# AntiRush

## What is this?
This plugin is a great replacement of AntiRush provided by CubeMath (at https://github.com/CubeMath/UCHFastDL2 repository), at least for Sven Co-op 5.26, meanwhile intoducing new borders at various places (and fixes for skips!) and a whole re-think of the placement of these borders.

## So why I may need it?
<ul>
<li>Are you and yours server players tired from rushers even with the CubeMath's AntiRush installed? This plugin is made for you.</li>
<li>Want to insert AntiRush into your maps or any other campaign not provided by CubeMath? Guess what - this plugin is made for you.</li>
<li>Want to experience something new? This plugin is ready to provide in-game editing of the AntiRush -- just use ".ar_reload" command inside console (make sure you're an admin) and it will apply the changes you inserted into the file!*</li>
</ul>

> \* Some things like "skull", "killcounter" and etc. require a full map restart to apply changes.

## How can I use it?
Fork this repo, then fully clone it. Drop all the stuff you just downloaded into `game_root_path_here/svencoop/scripts/plugins`, register `AntiRush.as` in `game_root_path_here/svencoop/default_plugins.txt` and you're done. This repository provides AntiRush for the whole Half-Life campaign (hl_c01_a1 till hl_c16_a4 maps) so you can fully experience the overhaul this plugin brings into the game.

> [!CAUTION]  
> Be aware that we require you to replace `scripts/maps/point_checkpoint.as` to our version in order to make the maps completable and extend the features provided by the Respawn-Point.

## Commands
<details>
  <summary>Click to expand</summary>
<ul>
<li>.ar_lookpos // Traces a line from your eyes to the point you're looking at and prints the coordinates of that point.</li>
<li>.ar_reload // Reloads &lt;game_root_path_here/svencoop/scripts/plugins/store/hlcancer/antirush/maps.txt&gt; and the maps specified inside this file.</li>
<li>.ar_getmodel // Get the modelindex of the brush entity you're looking at.</li>
<li>.ar_smartdivide &lt;num1&gt; &lt;num2&gt; &lt;divisor&gt; // Use this to properly align various AntiRush objects on map - specify &lt;num1&gt; and &lt;num2&gt;, pass 2 as the second argument and get the middle between these two numbers!</li>
</ul>
</details>

## I wanna insert AntiRush into my map, what do I do?
Read the Commands section, the `antirush_documentation.txt` file -- look at any of the maps we have provided and see how we implemented various tricks to prevent rushers. Do whatever you want!

If you ask seriously, it's pretty simple as well as the syntax we use to configure AntiRush for a map. Read about it below

## Syntax
We use a simple syntax to describe what we want to be placed on the map. An example: `wall|-150,-150,-150,150,150,150$_antirush_my_first_wall`.

This command creates a wall which starts at `-150 -150 -150` coords and ends at `150 150 150` coords. This means, in anything between, players can't get inside. Imagine the wall like an area you want to block.

How to make this wall disappear? Simple! Just use (read: activate) the entity with the name you just supplied. In the example, it is `_antirush_my_first_wall`.

Let's say we want this wall to disappear when players stand in area between coords `300 300 300` and `600 600 600`, and we need in total 66% of alive players stand in this area. We can utilize `counter` command here: `counter|300,300,300,600,600,600,0.66$_antirush_my_first_wall`.

When 66% of alive players group up in the area specified, the wall will magically disappear and they will be able to pass though. Nice and easy? It is!
