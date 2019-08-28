// Project: Cimex mortis 
// Created: 2019-08-25

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle( "Cimex mortis" )
SetWindowSize( 1920, 1080, 0 )
SetWindowAllowResize( 1 ) // allow the user to resize the window

// set display properties
SetVirtualResolution( 100, 100 ) // doesn't have to match the window
SetOrientationAllowed( 1, 1, 1, 1 ) // allow both portrait and landscape on mobile devices
//~ SetSyncRate( 0, 0 ) // 30fps instead of 60 to save battery
SetVsync(1)
SetScissor( 0,0,0,0 ) // use the maximum available screen space, no black borders
UseNewDefaultFonts( 1 ) // since version 2.0.22 we can use nicer default fonts

//~ SetShadowMappingMode(3) // built in shadows (for now at least)

//~ SetAntialiasMode(1)
SetDefaultWrapU(1)
SetDefaultWrapV(1)

#include "constants.agc"
#include "common.agc"
#include "bullets.agc"
#include "enemys.agc"
#include "path.agc"
#include "player.agc"
#include "debug.agc"

Create3DPhysicsWorld(1)
Set3DPhysicsGravity(0,0,0)

Create3DPhysicsStaticPlane(0,1,0, -10 )

GameState = -1

do
	Select GameState
		case STATE_GAME_INTRO
			GameState=IntroScreen()
		endcase
		case STATE_MAIN_MENU
			GameState=MainMenu()
		endcase
		case STATE_GAME_MENU
			GameState=GameMenu()
		endcase
		case STATE_GAME
			GameState=Game()
		endcase
	endselect
    Sync()
loop

function MainMenu()
	PlayTID=CreateText("Play")
	SetTextSize(PlayTID,12)
	ExitTID=CreateText("Exit")
	SetTextSize(ExitTID,12)
	SetTextPosition(ExitTID,0,12)
	do
		PointerX#=GetPointerX()
		PointerY#=GetPointerY()
		if GetTextHitTest(PlayTID,PointerX#,PointerY#)
			if GetPointerReleased()
				GameState=STATE_GAME_MENU
				exit
			endif
		endif
		if GetTextHitTest(ExitTID,PointerX#,PointerY#)
			if GetPointerReleased()
				GameState=-1
				end
			endif
		endif
		sync()
	loop
	DeleteText(PlayTID)
	DeleteText(ExitTID)
endfunction GameState

function GameMenu()
	MainTID=CreateText("Level Select")
	SetTextSize(MainTID,12)
	
	do
		PointerX#=GetPointerX()
		PointerY#=GetPointerY()
		if GetTextHitTest(MainTID,PointerX#,PointerY#)
			if GetPointerReleased()
				GameState=STATE_GAME
				exit
			endif
		endif
		sync()
	loop
	DeleteText(MainTID)
endfunction GameState

function Game()
	local GridSize
	GridSize=1
	
	Player as Player
	PlayerInit(Player,10)
	
	local PlayerGrid as int2
	PlayerGrid.x=round(Player.Character.Position.x/GridSize)
	PlayerGrid.y=round(Player.Character.Position.z/GridSize)
	
	Grid as PathGrid[64,64]
	
	// create some random walls
	for t = 1 to 10
		wall = CreateObjectBox(random2(10,35),5,1.5)
		SetObjectTransparency(wall,1)
		SetObjectPosition(wall,random2(1,50),2.5,random2(1,50))
		RotateObjectLocalY(wall,random2(0,360))
		setobjectcolor(wall,0,255,0,155)
	next t
	
	PathInit(Grid, 0.5, GridSize)
	PathFinding(Grid, PlayerGrid)
	
	Enemy as Character[50]
	EnemyInit(Enemy, Grid, GridSize)

	Bullets as Bullet[]
	
	Debug as Debuging
	
	// temporary ...help me do this in a nicer way please
	BulletShaderID=LoadShader("shader/Line.vs","shader/Default.ps")
	BulletDiffuseIID=LoadImage("bullet.png")
	
	width=GetDeviceWidth()
	height=GetDeviceHeight()
	SceneIID=CreateRenderImage(width,height,0,0)
	BlurHIID=CreateRenderImage(width*0.5,height*0.5,0,0)
	BlurVIID=CreateRenderImage(width*0.5,height*0.5,0,0)
	QuadOID=CreateObjectQuad()
	BlurHSID=LoadFullScreenShader("shader/BlurH.ps")
	BlurVSID=LoadFullScreenShader("shader/BlurV.ps")
	BloomSID=LoadFullScreenShader("shader/Bloom.ps")
	SetShaderConstantByName(BlurHSID,"blurScale",4.0,0,0,0)
	SetShaderConstantByName(BlurVSID,"blurScale",4.0,0,0,0)
	
	do
		Print( ScreenFPS() )
		print (player.state)
		print("Energy:"+str(Player.Energy))
		print("Attack:"+str(Player.Attack))
		print("Life:"+str(Player.Character.Life))
		print("mov-speed:"+str(Player.Character.MaxSpeed))
		
		PlayerControll(Player,10) // player speed set in PlayerInit (Velocity)
		EnemyControll(Enemy, Player, Grid, GridSize)
		
		if GetPointerPressed()
			BulletCreate(Bullets,Player.Character.Position.x,Player.Character.Position.y,Player.Character.Position.z,Player.Character.Rotation.y, BulletShaderID, BulletDiffuseIID, -1, Player.Attack)
		endif	
		
		BulletUpdate(Bullets)
		
		Debuging(Debug)

		if GetRawKeyReleased(27)
			GameState=STATE_GAME_MENU
			exit
		endif
		
		Step3DPhysicsWorld()
		
		if Debug.ShaderEnabled=0
			Update(0)
			Render2DBack()
			
			SetRenderToImage(SceneIID,-1)
			ClearScreen()
			Render3D()
			
			SetObjectImage(QuadOID,SceneIID,0)
			SetObjectShader(QuadOID,BlurHSID)
			SetRenderToImage(BlurHIID,0)
			ClearScreen()
			DrawObject(QuadOID)
			
			SetObjectImage(QuadOID,BlurHIID,0)
			SetObjectShader(QuadOID,BlurVSID)
			SetRenderToImage(BlurVIID,0)
			ClearScreen()
			DrawObject(QuadOID)
			
			SetObjectImage(QuadOID,SceneIID,0)
			SetObjectImage(QuadOID,BlurVIID,1)
			SetObjectShader(QuadOID,BloomSID)
			SetRenderToScreen()
			ClearScreen()
			DrawObject(QuadOID)
			
			DebugPath(Debug, Grid, GridSize)
			
			Render2DFront()
			Swap()
		else
			DebugPath(Debug, Grid, GridSize)
			sync()
		endif
	loop
endfunction GameState

function IntroScreen()
	FadeTween = CreateTweenSprite(1)
	SetTweenSpriteAlpha(FadeTween,0,255,TweenLinear())
	IntroScreenIID = loadimage("Intro_Screen.png")
	IntroScreenSID = CreateSprite(IntroScreenIID)
	SetSpriteSize(IntroScreenSID,ScreenWidth(),ScreenHeight())
	SetSpritePosition(IntroScreenSID,GetScreenBoundsLeft(),GetScreenBoundsTop())
	PlayTweenSprite(FadeTween,IntroScreenSID,0)
	repeat
		UpdateTweenSprite(FadeTween,IntroScreenSID,GetFrameTime())
		sync()
	until GetRawLastKey() or GetPointerPressed()
	
	DeleteTween(FadeTween)
	FadeTween = CreateTweenSprite(1)
	SetTweenSpriteAlpha(FadeTween,GetSpriteColorAlpha(IntroScreenSID),0,TweenLinear())
	PlayTweenSprite(FadeTween,IntroScreenSID,0)
	while GetTweenSpritePlaying(FadeTween,IntroScreenSID)
		UpdateTweenSprite(FadeTween,IntroScreenSID,GetFrameTime())
		sync()
	endwhile
endfunction STATE_MAIN_MENU
