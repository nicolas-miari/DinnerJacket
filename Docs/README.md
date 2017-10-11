Pretty much what it says in the can.



================================================================================
Memo: Multiple Resolution Support for Tilemap-Based Game
======================================================================

Ideally, the same map area should be visible at any single moment, on any 
device. That is, regardless of resolution, every screen should measure the same 
ammount of map tiles. This is so that the game is fair and equally dificult 
between people playing on different devices.

Scaling/resampling of resources is undesirable quality-wise, even in this age of 
high-desnsity displays where individual pixels can' be discerned. Instead, we 
preserve pixel-perfect graphics by redefining the tile size for each device (and 
supplying a different set of resources to back up each):


1. iPhone 3.5"/4": (320 pt wide) -> Tile size: 32 pt 
			(exactly 10 tiles wide)

2. iPhone 4.7": (375 pt wide) -> Tile size: 36 pt(*)
            (10.41+ tiles wide)
			
3. iPhone 5.5" (414 pt wide) -> Tile size: 40 pt
            (10.35 tiles wide)
			
4. iPad  (any) (768 pt wide) -> Tile Size: 76 pt
            (10.10+ tiles wide)


(*) Chose 36 instead of 37 because is a rounder number


There is the option of supplying only the highest resolution resource set (tile 
size: 76pt). But the lowest resolution is exactly half the size, and runtime 
downsampling of this scale produces visible artifacts (linear filtering in 
OpenGL ES). 

--------------------------------------------------------------------------------

IF having 4x the resources is unacceptable (both in terms of binary size and 
authoring time), we can compromise with:

1. An iPhone-specific resource set, created at the largest tile size: 40 pt 
(5.5"), and scale it down on other devices: 90% for 36pt devices (4.7") and 80% 
for 32 pt devices (3.5" and 4").

2. An iPad-specific resource set, scaled for tile size: 76pt.

