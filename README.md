# Makerspace_Bus_Timetable_v2
Bus timetable version 2
## Installation
```
git clone https://github.com/valemaio2/Makerspace_Bus_Timetable_v2.git
cd Makerspace_Bus_Timetable_v2
chmod +x install.sh
./install.sh
```
## Notes
To filter trains from Cardiff Central that can be caught with the first train from Waun-Gron Park, delete or rename the current scrape_buses.py file, and rename scrape_buses.py.TRAIN_FILTERING to scrape_buses.py.

This will search for the first train from Waun-Gron to either Cardiff Central or Merthyr Tydfyl, add 15 minutes and only show trains leaving from Cardiff Central that can be realistically caught.
