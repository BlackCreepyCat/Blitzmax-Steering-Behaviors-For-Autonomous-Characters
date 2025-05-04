' ------------------------------------------------
' Name : Steering Behaviors For Autonomous Characters
' Date : (C)2025
' Site:https://github.com/BlackCreepyCat
' -----------------------------------------------

SuperStrict

' ========== Vector2 ==========
Type Vector2
	Field x:Float
	Field y:Float

	Function Create:Vector2(x:Float = 0, y:Float = 0)
		Local v:Vector2 = New Vector2
		v.x = x; v.y = y
		Return v
	End Function
	
	Method Add(v:Vector2)
		x :+ v.x; y :+ v.y
	End Method
	
	Method Subtract(v:Vector2)
		x :- v.x; y :- v.y
	End Method
	
	Method Scale(s:Float)
		x :* s; y :* s
	End Method
	
	Method Normalize()
		Local m:Float = Magnitude()
		If m > 0 Then x :/ m; y :/ m
	End Method
	
	Method Magnitude:Float()
		Return Sqr(x * x + y * y)
	End Method
	
	Method Truncate(max:Float)
		If Magnitude() > max Then
			Normalize()
			Scale(max)
		EndIf
	End Method
	
	Function Sub:Vector2(a:Vector2, b:Vector2)
		Return Create(a.x - b.x, a.y - b.y)
	End Function
	
	Function Distance:Float(a:Vector2, b:Vector2)
		Return Sub(a, b).Magnitude()
	End Function
	
	Function Copy:Vector2(v:Vector2)
		Return Create(v.x, v.y)
	End Function
End Type

' ========== Vehicle ==========
Type Vehicle
	Field position:Vector2
	Field velocity:Vector2
	Field acceleration:Vector2
	
	Field maxSpeed:Float = 2.5
	Field maxForce:Float = 0.1
	
	Field wanderRadius:Float = 50
	Field wanderDistance:Float = 80	
	Field wanderAngle:Float = 0
	
	Field desiredSeparation:Float = 35
	Field neighborDist:Float = 60
		
	Field r:Int, g:Int, b:Int, Alpha:Float ' Couleur et opacité
					
	Method New()
		position = Vector2.Create(float(Rnd(800)),Float( Rnd(600)))
		velocity = Vector2.Create(Float(Rnd(-1, 1)), Float(Rnd(-1, 1)))
		acceleration = Vector2.Create()
	End Method
	
	Method ApplyForce(force:Vector2)
		acceleration.Add(force)
	End Method
	
	Method Seek(target:Vector2)
		Local desired:Vector2 = Vector2.Sub(target, Position)
		desired.Normalize(); desired.Scale(maxSpeed)
		Local steer:Vector2 = Vector2.Sub(desired, velocity)
		steer.Truncate(maxForce)
		ApplyForce(steer)
	End Method
	
	Method Flee(target:Vector2)
		Local desired:Vector2 = Vector2.Sub(Position, target)
		desired.Normalize(); desired.Scale(maxSpeed)
		Local steer:Vector2 = Vector2.Sub(desired, velocity)
		steer.Truncate(maxForce)
		ApplyForce(steer)
	End Method
	
	Method Arrive(target:Vector2)
		Local desired:Vector2 = Vector2.Sub(target, Position)
		Local d:Float = desired.Magnitude()
		desired.Normalize()
		If d < 100 Then desired.Scale((d / 100) * maxSpeed) Else desired.Scale(maxSpeed)
		Local steer:Vector2 = Vector2.Sub(desired, velocity)
		steer.Truncate(maxForce)
		ApplyForce(steer)
	End Method
	
	Method Wander()
		Local change:Float = 0.3
		wanderAngle :+ Rnd(-change, change)
		Local circleCenter:Vector2 = Vector2.Copy(velocity)
		circleCenter.Normalize(); circleCenter.Scale(wanderDistance)
		Local displacement:Vector2 = Vector2.Create(Float(Cos(wanderAngle)), Float(Sin(wanderAngle)))
		displacement.Scale(wanderRadius)
		Local wanderForce:Vector2 = Vector2.Create(circleCenter.x + displacement.x, circleCenter.y + displacement.y)
		wanderForce.Truncate(maxForce)
		ApplyForce(wanderForce)
	End Method
	
	Method Pursue(target:Vehicle)
		Local future:Vector2 = Vector2.Copy(target.Position)
		Local prediction:Vector2 = Vector2.Copy(target.velocity)
		prediction.Scale(10)
		future.Add(prediction)
		Seek(future)
	End Method
	
	Method Evade(target:Vehicle)
		Local future:Vector2 = Vector2.Copy(target.Position)
		Local prediction:Vector2 = Vector2.Copy(target.velocity)
		prediction.Scale(10)
		future.Add(prediction)
		Flee(future)
	End Method
	
	Method Flock(others:Vehicle[])
		Local sep:Vector2 = Separate(others)
		Local ali:Vector2 = Align(others)
		Local coh:Vector2 = Cohesion(others)
		
		sep.Scale(1.5)
		ali.Scale(1.0)
		coh.Scale(1.0)
		
		ApplyForce(sep)
		ApplyForce(ali)
		ApplyForce(coh)
	End Method
	
	Method Separate:Vector2(others:Vehicle[])

		Local steer:Vector2 = Vector2.Create()
		Local Count:Int = 0
		
		For Local other:Vehicle = EachIn others
			Local d:Float = Vector2.Distance(Position, other.Position)
			If other <> Self And d > 0 And d < desiredSeparation
				Local diff:Vector2 = Vector2.Sub(Position, other.Position)
				diff.Normalize(); diff.Scale(1 / d)
				steer.Add(diff)
				count :+ 1
			EndIf
		Next
		If count > 0 Then steer.Scale(1.0 / count)
		If steer.Magnitude() > 0
			steer.Normalize(); steer.Scale(maxSpeed)
			steer.Subtract(velocity)
			steer.Truncate(maxForce)
		EndIf
		Return steer
	End Method
	
	Method Align:Vector2(others:Vehicle[])

		Local sum:Vector2 = Vector2.Create()
		Local Count:Int = 0
		
		For Local other:Vehicle = EachIn others
			Local d:Float = Vector2.Distance(Position, other.Position)
			If other <> Self And d < neighborDist
				sum.Add(other.velocity)
				count :+ 1
			EndIf
		Next
		If count > 0
			sum.Scale(1.0 / count)
			sum.Normalize(); sum.Scale(maxSpeed)
			Local steer:Vector2 = Vector2.Sub(sum, velocity)
			steer.Truncate(maxForce)
			Return steer
		EndIf
		Return Vector2.Create()
	End Method
	
	Method Cohesion:Vector2(others:Vehicle[])

		Local sum:Vector2 = Vector2.Create()
		Local count:Int = 0
		For Local other:Vehicle = EachIn others
			Local d:Float = Vector2.Distance(Position, other.Position)
			If other <> Self And d < neighborDist
				sum.Add(other.position)
				count :+ 1
			EndIf
		Next
		If count > 0
			sum.Scale(1.0 / count)
			Return SeekReturn(sum)
		EndIf
		Return Vector2.Create()
	End Method
	
	Method SeekReturn:Vector2(target:Vector2)
		Local desired:Vector2 = Vector2.Sub(target, Position)
		desired.Normalize(); desired.Scale(maxSpeed)
		Local steer:Vector2 = Vector2.Sub(desired, velocity)
		steer.Truncate(maxForce)
		Return steer
	End Method
	
	Method Update()
		velocity.Add(acceleration)
		velocity.Truncate(maxSpeed)
		position.Add(velocity)
		acceleration = Vector2.Create()
		
		' Wrap around screen
		If Position.x < 0 Then Position.x = GraphicsWidth()
		If Position.x > GraphicsWidth() Then Position.x = 0
		If Position.y < 0 Then Position.y = GraphicsHeight()
		If Position.y > GraphicsHeight() Then Position.y = 0
	End Method
	
	Method Draw()
		' Ligne de direction (vitesse)
		SetColor 50 ,50,50
		DrawLine Position.x, Position.y, Position.x + velocity.x * 10, Position.y + velocity.y * 10
		
		SetColor 0, 255, 0
		DrawOval(Position.x - 5, Position.y - 5, 10, 10)
		

	End Method
End Type

' ========== MAIN ==========
Graphics 1920, 1080
SeedRnd MilliSecs()

Global mode:Int = 0
Global modeNames$[] = ["Seek", "Flee", "Arrive", "Wander", "Pursue", "Evade", "Flocking"]

Global target:Vector2 = Vector2.Create(400, 300)
Global vehicleB:Vehicle = New Vehicle
Global enemy:Vehicle = New Vehicle
enemy.maxSpeed = 2

Global vehiclesB:Vehicle[] = []

' créer un groupe pour le flocking
For Local i:Int = 0 Until 400
	vehiclesB:+[New Vehicle]
Next

While Not KeyDown(KEY_ESCAPE)
	Cls
	
	If KeyHit(KEY_SPACE)
		mode = (mode + 1) Mod modeNames.length
	EndIf
	
	target.x = MouseX()
	target.y = MouseY()
	
	Select mode
		Case 0
			vehicleB.seek(target)
			vehicleB.Update()
			vehicleB.Draw()
		Case 1
			vehicleB.Flee(target)
			vehicleB.Update()
			vehicleB.Draw()
		Case 2
			vehicleB.Arrive(target)
			vehicleB.Update()
			vehicleB.Draw()
		Case 3
			vehicleB.Wander()
			vehicleB.Update()
			vehicleB.Draw()
		Case 4
			enemy.Seek(target)
			enemy.Update()
			enemy.Draw()
			vehicleB.Pursue(enemy)
			vehicleB.Update()
			vehicleB.Draw()
		Case 5
			enemy.Seek(target)
			enemy.Update()
			enemy.Draw()
			vehicleB.Evade(enemy)
			vehicleB.Update()
			vehicleB.Draw()
		Case 6
			For Local v:Vehicle = EachIn vehiclesB
			
		'	V.seek(target)
			
				v.Flock(vehiclesB)
				v.Update()
				v.Draw()
			Next
			
		'	V.seek(target)
	End Select
	
	SetColor 255,255,255
	DrawText "Mode: " + modeNames[mode], 10, 10
	
	SetColor 255,0,0
	DrawOval(target.x - 3, target.y - 3, 6, 6)
	
	Flip
Wend
