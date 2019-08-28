type Player
	Character		as Character
	Energy			as float
	Attack			as float
	OldGrid			as int2
	Boost_TweenID	as integer
	State 			as integer
endtype

function PlayerInit(Player ref as Player, CameraDistance#)
	Player.Character.OID=CreateObjectBox(1,1,1)
	Player.Character.MaxSpeed=8.0
	Player.Character.Position.x=32
	Player.Character.Position.y=0
	Player.Character.Position.z=32
	Player.Attack = 0.9
	SetObjectPosition(Player.Character.OID,Player.Character.Position.x,Player.Character.Position.y,Player.Character.Position.z)
	SetCameraPosition(1,Player.Character.Position.x,Player.Character.Position.y+CameraDistance#,Player.Character.Position.z-CameraDistance#)
	SetCameraLookAt(1,Player.Character.Position.x,Player.Character.Position.y,Player.Character.Position.z,0)
	Player.Boost_TweenID = CreateTweenCustom(0.3)
	SetTweenCustomFloat1(Player.Boost_TweenID,100,0,TweenSmooth2())
	Create3DPhysicsDynamicBody(Player.Character.OID)
endfunction

function PlayerControll(Player ref as Player, CameraDistance#) // player speed is in the Player character type
	FrameTime#=GetFrameTime()
	CameraAngleY#=GetCameraAngleY(1)
	CameraX#=GetCameraX(1)
	CameraY#=GetCameraY(1)
	CameraZ#=GetCameraZ(1)
	PointerX#=GetPointerX()
	PointerY#=GetPointerY()
	
	Sin0#=sin(CameraAngleY#)
	Sin90#=sin(CameraAngleY#+90.0)
	Cos0#=cos(CameraAngleY#)
	
	if GetRawKeyPressed(32)
		PlayTweenCustom(Player.Boost_TweenID,0.0)
	endif
	
	if GetRawMouseRightState() 
		player.State=STATE_SUCK
	else
		player.state=0
	endif
	
	if GetTweenCustomPlaying(player.Boost_TweenID)
		print("Boost")
		UpdateTweenCustom(player.Boost_TweenID,GetFrameTime())
	endif
	
	SpeedBoost# = GetTweenCustomFloat1(player.Boost_TweenID)
	
    if GetRawKeyState(KEY_W)
		MoveZ1#=(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#
		MoveX1#=(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#
		SetObject3DPhysicsLinearVelocity(Player.Character.OID,0,0,1, 4)
    endif
    if GetRawKeyState(KEY_S)
		MoveZ1#=-(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#
		MoveX1#=-(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#
		SetObject3DPhysicsLinearVelocity(Player.Character.OID,0,0,-1, 4)
    endif
    if GetRawKeyState(KEY_A)
		MoveZ2#=(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#
		MoveX2#=-(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#
		SetObject3DPhysicsLinearVelocity(Player.Character.OID,-1,0,0, 4)
    endif
    if GetRawKeyState(KEY_D)
		MoveZ2#=-(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#
		MoveX2#=(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#
		SetObject3DPhysicsLinearVelocity(Player.Character.OID,1,0,0, 4)
    endif
    
    if GetRawKeyState(KEY_SPACE)
		Select player.state
			
			case STATE_FORWARD
				MoveZ1#=(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#)
				MoveX1#=(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#)
			endcase
			
			case STATE_BACKWARD
				MoveZ1#=-(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#)
				MoveX1#=-(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#)
			endcase
					
			case STATE_LEFT
				MoveZ2#=(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#)
				MoveX2#=-(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#)
			endcase
			
			case STATE_RIGHT
				MoveZ2#=-(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin0#)
				MoveX2#=(BOOST_AMMOUNT*(Player.Character.MaxSpeed+SpeedBoost#)*Sin90#)
			endcase
		endselect		
    endif
	
    MoveY#=0
	Player.Character.Velocity.x=curvevalue((MoveX1#+MoveX2#)*FrameTime#,Player.Character.Velocity.x,3.0)
	Player.Character.Velocity.y=curvevalue((MoveY#)*FrameTime#,Player.Character.Velocity.y,0.2)
	Player.Character.Velocity.z=curvevalue((MoveZ1#+MoveZ2#)*FrameTime#,Player.Character.Velocity.z,3.0)
	
	Player.Character.Position.x=Player.Character.Position.x+Player.Character.Velocity.x
	Player.Character.Position.y=Player.Character.Position.y+Player.Character.Velocity.y
	Player.Character.Position.z=Player.Character.Position.z+Player.Character.Velocity.z
	
	OldPlayerX#=GetObjectX(Player.Character.OID)
	OldPlayerY#=GetObjectY(Player.Character.OID)
	OldPlayerZ#=GetObjectZ(Player.Character.OID)
	
	//~ if ObjectSphereSlide(0,OldPlayerX#,OldPlayerY#,OldPlayerZ#,Player.Character.Position.x,Player.Character.Position.y,Player.Character.Position.z,0.3)>0
		//~ Player.Character.Position.x=GetObjectRayCastSlideX(0)
		//~ Player.Character.Position.z=GetObjectRayCastSlideZ(0)
	//~ endif
	
	// Player to look at mouse position
	Pointer3DX#=Get3DVectorXFromScreen(PointerX#,PointerY#)
    Pointer3DY#=Get3DVectorYFromScreen(PointerX#,PointerY#)
    Pointer3DZ#=Get3DVectorZFromScreen(PointerX#,PointerY#)

    Length#=-CameraY#/Pointer3DY#

    Pointer3DX#=CameraX#+Pointer3DX#*Length#
    Pointer3DY#=Player.Character.Position.y
    Pointer3DZ#=CameraZ#+Pointer3DZ#*Length#

	DistX#=Pointer3DX#-Player.Character.Position.x
	DistZ#=Pointer3DZ#-Player.Character.Position.z
	
	NewAngle#=-atanfull(DistX#,DistZ#)
	OldAngleY#=Player.Character.Rotation.y
	Player.Character.Rotation.y=CurveAngle(Player.Character.Rotation.y,NewAngle#,6.0)
	AngleVelocity#=Player.Character.Rotation.y-OldAngleY#
	Player.Character.Position.x=GetObjectX(Player.Character.OID)
	Player.Character.Position.y=GetObjectY(Player.Character.OID)
	Player.Character.Position.z=GetObjectZ(Player.Character.OID)
	//~ SetObject3DPhysicsAngularVelocity(Player.Character.OID, 0, AngleVelocity#, 0, 6.0 )
	Player.Character.Rotation.y=GetObjectAngleY(Player.Character.OID)
	//~ SetObjectPosition(Player.Character.OID,Player.Character.Position.x,Player.Character.Position.y,Player.Character.Position.z)
	//~ SetObjectRotation(Player.Character.OID,Player.Character.Rotation.x,Player.Character.Rotation.y,Player.Character.Rotation.z)
	//~ SetCameraPosition(1,Player.Position.x+CameraDistance#*Sin0#,Player.Position.y+CameraDistance#,Player.Position.z+CameraDistance#*Cos0#)
	//~ SetCameraLookAt(1,Player.Position.x,Player.Position.y,Player.Position.z,0)
	SetCameraPosition(1,Player.Character.Position.x,Player.Character.Position.y+CameraDistance#,Player.Character.Position.z-CameraDistance#)
endfunction

function Pick(X# as float, Y# as float) // returns 3D object ID from screen x/y coordinates.
	Result = -1
	WorldX# = Get3DVectorXFromScreen( X#, Y# ) * 800
    WorldY# = Get3DVectorYFromScreen( X#, Y# ) * 800
    WorldZ# = Get3DVectorZFromScreen( X#, Y# ) * 800
    WorldX# = WorldX# + GetCameraX( 1 )
    WorldY# = WorldY# + GetCameraY( 1 )
    WorldZ# = WorldZ# + GetCameraZ( 1 )
 
 	Result=ObjectRayCast(0,getcamerax(1),getcameray(1),getcameraz(1), Worldx#,Worldy#,Worldz#)
endfunction Result
