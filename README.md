Easy little script I made to setup my autosave system for ToME.

The autosave system syncs your save files and profile(unlocks) to a github repository.

It SHOULD compare dates on same named files and keep the newest. (recommend backing up save and profiles folders before running the script)


HOW TO USE:
Simply download the zip or clone this repo.
Open the .bat in a file editor and change the repo address to a new private repo you create and change $LocalRepo = "$env:USERPROFILE\YOUR MAIN REPO FOLDER HERE" to reflect what you name the repo. save and run the bat.

after it finishes you will find the new repo folder pull to the location show in the script. Inside will be your saves and it should have already made an initial commit.

Make a shortcut of the .bat in the new repo folder and use it to launch ToME for now on (it will automatically pull latest saves and then push when you exit the game)

(first time making a PS script to automate git so be kind)
