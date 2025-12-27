# Left 4 Rank
Creates a ranking system that works across multiple servers.

!rank, to view your rank

## Requirements
- [Any Sourcemod compatible Database](https://www.mysql.com/)
- Sourcemod and metamod

## Command line
- -rankDisableAutoMenu ``Disables menu when player spawn``
- -debug ``Additional infos when playing for debug porpuses``

## Usage
1. Download the plugin from the latest release:
[Releases Section](https://github.com/LeandroTheDev/left_4_rank/releases)

2. Place the compiled .smx file into the following folder on your server: addons/sourcemod/plugins/

3. Configure database in addons/sourcemod/configs/database.cfg
```
"left4rank"
{
    "driver"    "default"
    "host"      "127.0.0.1"
    "database"  "mydatabase"
    "pass"      "ultrasecret"
}
```

4. Create the database and table, table must be ``left4dead2`` because the plugin use the game name as table
```sql
CREATE mydatabase
USE mydatabase
CREATE TABLE left4dead2 (
    uniqueid VARCHAR(255) NOT NULL PRIMARY KEY,
    rank DECIMAL(50, 0) NOT NULL DEFAULT 0
);
```

5. Run the server

## Compiling

- Use the compiler from sourcemod to compile the left_4_rank.sp

