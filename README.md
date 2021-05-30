# Endless Dungeon (Procedural Game Showcase)
This game was created as part of my bachelor thesis. The thesis shows the concept and implementation process of a video game using different procedural content generation concepts.
The content is generated using an online approach. The generated map supports multiple types of barriers. Multi-level barriers are supported while keeping every room accessible.
Additionally, gameplay elements are shown supporting dynamic difficulty adaption. The presented algorithms show the benefits of using an online 
approach for Procedural Dungeon Generation (PDG). Everything combined to created a fully playable game presenting the interactions of these components. 

## What it is 
The goal of the implementation is to create a playable prototype of a gamecombining multiple PCG techniques. The ones combined are online generation,adaption and barriers.
The online approach showcases a possibility to createmulti-level barriers without the need of a search algorithm.There is no final goal to the game, one plays
until defeated or quitting the game.The game is playable until one of those events occurs. The map generation algo-rithm was created in such ways,
that every room has to be accessible, thereforeno dead ends and soft locks can occur. Depending on the initial game settings,whenever starting a new game,
the map generation and difficulty change andadapt  in  different  ways. The  main  influence  for  the  adaption  is  the  players’progression.
using a multitude of tracked stats.  The finished prototype includesall  aspects  of  a  modern  video  game  including  visuals  and  sound.
This  is  toshowcase the created algorithms in a natural habitat.

## Why it was created
I am a big fan of rogue like games (The Binding of Isaac, Spelunky, Slay the Spire etc) and was always interested in understanding the process of procedural game design. 
For me personally the goal was to get an idea of how procedural content can be used to not only prolong the game but to adapt to the players needs. Furthermore, this was
my first game using the Godot game engine. It was a journey to say the least but in the end I had created my first fully playable game. 

## Want to know more? 
An extended overview of everything created can be found in the PDF of the thesis found in this repository and the game can be played here: https://l4igi.itch.io/endless-dungeon
