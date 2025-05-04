SuperStrict

' ========== Vector2 ==========
' Représente un vecteur 2D pour gérer positions, vitesses, ou forces dans un espace bidimensionnel.
Type Vector2
    ' x:Float - Coordonnée horizontale (axe des abscisses)
    ' y:Float - Coordonnée verticale (axe des ordonnées)
    Field x:Float
    Field y:Float

    ' Crée un nouveau vecteur avec des coordonnées x et y (par défaut 0).
    Function Create:Vector2(x:Float = 0, y:Float = 0)
        Local v:Vector2 = New Vector2
        v.x = x; v.y = y
        Return v
    End Function
    
    ' Ajoute les coordonnées d’un autre vecteur v au vecteur courant.
    Method Add(v:Vector2)
        x :+ v.x; y :+ v.y
    End Method
    
    ' Soustrait les coordonnées d’un autre vecteur v du vecteur courant.
    Method Subtract(v:Vector2)
        x :- v.x; y :- v.y
    End Method
    
    ' Multiplie les coordonnées x et y par un scalaire s.
    Method Scale(s:Float)
        x :* s; y :* s
    End Method
    
    ' Normalise le vecteur pour qu’il ait une magnitude de 1 (vecteur unitaire).
    Method Normalize()
        Local m:Float = Magnitude()
        If m > 0 Then x :/ m; y :/ m
    End Method
    
    ' Calcule la magnitude (longueur) du vecteur avec la formule √(x² + y²).
    Method Magnitude:Float()
        Return Sqr(x * x + y * y)
    End Method
    
    ' Limite la magnitude du vecteur à max, en normalisant et mettant à l’échelle si nécessaire.
    Method Truncate(max:Float)
        If Magnitude() > max Then
            Normalize()
            Scale(max)
        EndIf
    End Method
    
    ' Retourne un nouveau vecteur représentant la différence entre deux vecteurs a et b.
    Function Sub:Vector2(a:Vector2, b:Vector2)
        Return Create(a.x - b.x, a.y - b.y)
    End Function
    
    ' Crée un vecteur représentant la différence entre deux points (ax, ay) et (bx, by).
    Function SubXY:Vector2(ax:Float, ay:Float, bx:Float, by:Float)
        Return Create(ax - bx, ay - by)
    End Function
    
    ' Calcule la distance euclidienne entre deux vecteurs a et b.
    Function Distance:Float(a:Vector2, b:Vector2)
        Return Sub(a, b).Magnitude()
    End Function
    
    ' Calcule la distance euclidienne entre deux points (ax, ay) et (bx, by).
    Function DistanceXY:Float(ax:Float, ay:Float, bx:Float, by:Float)
        Local dx:Float = ax - bx
        Local dy:Float = ay - by
        Return Sqr(dx * dx + dy * dy)
    End Function
    
    ' Crée une copie d’un vecteur v avec les mêmes coordonnées.
    Function Copy:Vector2(v:Vector2)
        Return Create(v.x, v.y)
    End Function
End Type

' ========== Vehicle ==========
' Représente un agent autonome avec des comportements comme seek, flee, ou flocking.
Type Vehicle
    ' positionX:Float, positionY:Float - Coordonnées actuelles du véhicule dans l’espace 2D
    ' velocityX:Float, velocityY:Float - Composantes de la vitesse (direction et magnitude)
    ' accelerationX:Float, accelerationY:Float - Composantes de l’accélération (forces appliquées)
    Field positionX:Float
    Field positionY:Float
    Field velocityX:Float
    Field velocityY:Float
    Field accelerationX:Float
    Field accelerationY:Float
    
    ' MaxSpeed:Float - Vitesse maximale du véhicule (par défaut 2.0)
    ' maxForce:Float - Magnitude maximale des forces de direction (par défaut 0.3)
    Field MaxSpeed:Float = 2.0
    Field maxForce:Float = 0.3
    
    ' wanderRadius:Float - Rayon du cercle pour l’errance (amplitude des variations)
    ' wanderDistance:Float - Distance devant le véhicule pour le cercle d’errance
    ' wanderAngle:Float - Angle actuel pour l’errance, modifié aléatoirement
    Field wanderRadius:Float = 50
    Field wanderDistance:Float = 80    
    Field wanderAngle:Float = 0
    
    ' desiredSeparation:Float - Distance minimale souhaitée pour la séparation (flocking)
    ' neighborDist:Float - Distance maximale pour considérer un voisin (flocking)
    ' fleeRadius:Float - Rayon pour fuir ou éviter une cible
    Field desiredSeparation:Float = 25
    Field neighborDist:Float = 40
    Field fleeRadius:Float = 100 ' Zone de fuite pour Flee et Evade
    
    ' arriveRadius:Float - Rayon de la zone circulaire autour de la cible pour le mode Arrive
    Field arriveRadius:Float = 30
    
    ' r:Int, g:Int, b:Int, Alpha:Float - Couleur (RVB) et opacité pour le rendu
    Field r:Int, g:Int, b:Int, Alpha:Float ' Couleur et opacité
                    
    ' Constructeur : initialise position aléatoire, vitesse aléatoire, accélération nulle
    Method New()
        positionX = Float(Rnd(800))
        positionY = Float(Rnd(600))
        velocityX = Float(Rnd(-1, 1))
        velocityY = Float(Rnd(-1, 1))
        accelerationX = 0
        accelerationY = 0
        r = 255
        g = 255
        b = 255
        Alpha = 1.0
        arriveRadius = 30 ' Valeur par défaut pour le rayon d'arrêt
    End Method
    
    ' Ajoute une force (vecteur) à l’accélération du véhicule.
    Method ApplyForce(force:Vector2)
        accelerationX :+ force.x
        accelerationY :+ force.y
    End Method
    
	' Calcule une force pour se diriger vers une cible et s’arrêter à une distance arriveRadius.
	Method Seek(target:Vector2)
	    Local desired:Vector2 = Vector2.SubXY(target.x, target.y, positionX, positionY)
	    Local d:Float = desired.Magnitude()
	    
	    If d <= arriveRadius
	        ' Si l'agent est dans la zone d'arrêt, aucune force n'est appliquée (il s'arrête)
	        Return
	    EndIf
	    
	    desired.Normalize()
	    If d < 100 ' Zone de ralentissement (commence à 100 pixels)
	        ' Réduit la vitesse proportionnellement à la distance restante jusqu'à arriveRadius
	        Local targetSpeed:Float = maxSpeed * (d - arriveRadius) / (100 - arriveRadius)
	        desired.Scale(targetSpeed)
	    Else
	        desired.Scale(maxSpeed)
	    EndIf
	    
	    Local steer:Vector2 = Vector2.Sub(desired, Vector2.Create(velocityX, velocityY))
	    steer.Truncate(maxForce)
	    ApplyForce(steer)
	End Method
    
    ' Calcule une force pour s’éloigner d’une cible si elle est dans fleeRadius.
    Method Flee(target:Vector2)
        Local desired:Vector2 = Vector2.SubXY(positionX, positionY, target.x, target.y)
        Local d:Float = desired.Magnitude()
        If d < fleeRadius
            desired.Normalize(); desired.Scale(maxSpeed)
            Local steer:Vector2 = Vector2.Sub(desired, Vector2.Create(velocityX, velocityY))
            steer.Truncate(maxForce)
            ApplyForce(steer)
        EndIf
    End Method
    
    ' Calcule une force pour s’approcher d’une cible et s’arrêter à une distance arriveRadius.
    Method Arrive(target:Vector2)
        Local desired:Vector2 = Vector2.SubXY(target.x, target.y, positionX, positionY)
        Local d:Float = desired.Magnitude()
        
        If d <= arriveRadius
            ' Si l'agent est dans la zone d'arrêt, aucune force n'est appliquée (il s'arrête)
            Return
        EndIf
        
        desired.Normalize()
        If d < 100 ' Zone de ralentissement (commence à 100 pixels)
            ' Réduit la vitesse proportionnellement à la distance restante jusqu'à arriveRadius
            Local targetSpeed:Float = maxSpeed * (d - arriveRadius) / (100 - arriveRadius)
            desired.Scale(targetSpeed)
        Else
            desired.Scale(maxSpeed)
        EndIf
        
        Local steer:Vector2 = Vector2.Sub(desired, Vector2.Create(velocityX, velocityY))
        steer.Truncate(maxForce)
        ApplyForce(steer)
    End Method
    
    ' Implémente un comportement d’errance avec un cercle projeté et un déplacement aléatoire.
    Method Wander()
        Local change:Float = 0.3
        wanderAngle :+ Rnd(-change, change)
        Local circleCenter:Vector2 = Vector2.Create(velocityX, velocityY)
        circleCenter.Normalize(); circleCenter.Scale(wanderDistance)
        Local displacement:Vector2 = Vector2.Create(Float(Cos(wanderAngle)), Float(Sin(wanderAngle)))
        displacement.Scale(wanderRadius)
        Local wanderForce:Vector2 = Vector2.Create(circleCenter.x + displacement.x, circleCenter.y + displacement.y)
        wanderForce.Truncate(maxForce)
        ApplyForce(wanderForce)
    End Method
    
    ' Poursuit un autre véhicule en prédisant sa position future.
    Method Pursue(target:Vehicle)
        Local future:Vector2 = Vector2.Create(target.positionX, target.positionY)
        Local prediction:Vector2 = Vector2.Create(target.velocityX, target.velocityY)
        prediction.Scale(10)
        future.Add(prediction)
        Seek(future)
    End Method
    
    ' Évite un autre véhicule en fuyant sa position future prédite.
    Method Evade(target:Vehicle)
        Local future:Vector2 = Vector2.Create(target.positionX, target.positionY)
        Local prediction:Vector2 = Vector2.Create(target.velocityX, target.velocityY)
        prediction.Scale(10)
        future.Add(prediction)
        Local d:Float = Vector2.DistanceXY(positionX, positionY, future.x, future.y)
        If d < fleeRadius
            Flee(future)
        EndIf
    End Method
    
    ' Combine séparation, alignement et cohésion pour le flocking.
    Method Flock(others:TList)
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
    
    ' Calcule une force pour s’éloigner des voisins trop proches.
    Method Separate:Vector2(others:TList)
        Local steer:Vector2 = Vector2.Create()
        Local Count:Int = 0
        
        For Local other:Vehicle = EachIn others
            Local d:Float = Vector2.DistanceXY(positionX, positionY, other.positionX, other.positionY)
            If other <> Self And d > 0 And d < desiredSeparation
                Local diff:Vector2 = Vector2.SubXY(positionX, positionY, other.positionX, other.positionY)
                diff.Normalize(); diff.Scale(1 / d)
                steer.Add(diff)
                count :+ 1
            EndIf
        Next
        If count > 0 Then steer.Scale(1.0 / count)
        If steer.Magnitude() > 0
            steer.Normalize(); steer.Scale(maxSpeed)
            steer.Subtract(Vector2.Create(velocityX, velocityY))
            steer.Truncate(maxForce)
        EndIf
        Return steer
    End Method
    
    ' Calcule une force pour s’aligner sur la vitesse moyenne des voisins.
    Method Align:Vector2(others:TList)
        Local sum:Vector2 = Vector2.Create()
        Local Count:Int = 0
        
        For Local other:Vehicle = EachIn others
            Local d:Float = Vector2.DistanceXY(positionX, positionY, other.positionX, other.positionY)
            If other <> Self And d < neighborDist
                sum.Add(Vector2.Create(other.velocityX, other.velocityY))
                count :+ 1
            EndIf
        Next
        If count > 0
            sum.Scale(1.0 / count)
            sum.Normalize(); sum.Scale(maxSpeed)
            Local steer:Vector2 = Vector2.Sub(sum, Vector2.Create(velocityX, velocityY))
            steer.Truncate(maxForce)
            Return steer
        EndIf
        Return Vector2.Create()
    End Method
    
    ' Calcule une force pour se rapprocher du centre de masse des voisins.
    Method Cohesion:Vector2(others:TList)
        Local sum:Vector2 = Vector2.Create()
        Local count:Int = 0
        
        For Local other:Vehicle = EachIn others
            Local d:Float = Vector2.DistanceXY(positionX, positionY, other.positionX, other.positionY)
            If other <> Self And d < neighborDist
                sum.Add(Vector2.Create(other.positionX, other.positionY))
                count :+ 1
            EndIf
        Next
        If count > 0
            sum.Scale(1.0 / count)
            Return SeekReturn(sum)
        EndIf
        Return Vector2.Create()
    End Method
    
    ' Version de Seek qui retourne la force sans l’appliquer.
    Method SeekReturn:Vector2(target:Vector2)
        Local desired:Vector2 = Vector2.SubXY(target.x, target.y, positionX, positionY)
        desired.Normalize(); desired.Scale(maxSpeed)
        Local steer:Vector2 = Vector2.Sub(desired, Vector2.Create(velocityX, velocityY))
        steer.Truncate(maxForce)
        Return steer
    End Method
    
    ' Met à jour la vitesse, la position, et gère le wrap-around de l’écran.
    Method Update()
        velocityX :+ accelerationX
        velocityY :+ accelerationY
        
        Local speed:Float = Sqr(velocityX * velocityX + velocityY * velocityY)
        
        If speed > maxSpeed
            Local scale:Float = maxSpeed / speed
            velocityX :* scale
            velocityY :* scale
        EndIf
        
        positionX :+ velocityX
        positionY :+ velocityY
        
        accelerationX = 0
        accelerationY = 0
        
        ' Wrap around screen
        If positionX < 0 Then positionX = GraphicsWidth()
        If positionX > GraphicsWidth() Then positionX = 0
        If positionY < 0 Then positionY = GraphicsHeight()
        If positionY > GraphicsHeight() Then positionY = 0
    End Method
    
    ' Dessine le véhicule (zone de fuite, ligne de vitesse, cercle).
    Method Draw()
        SetBlend(ALPHABLEND)
        
        SetColor 50, 100, 150
        SetAlpha 0.03
        DrawOval positionX - (fleeRadius / 2), positionY - (fleeRadius / 2), fleeRadius, fleeRadius
        
        SetColor 150, 150, 50
        SetAlpha 0.04
        DrawOval positionX - (wanderRadius / 2), positionY - (wanderRadius / 2), wanderRadius, wanderRadius
        
        SetAlpha 0.9
        SetColor 50, 50, 50
        DrawLine positionX, positionY, positionX + velocityX * 10, positionY + velocityY * 10
        
        SetAlpha Alpha
        SetColor r, g, b
        DrawOval(positionX - 5, positionY - 5, 10, 10)
    End Method
End Type

' Configure une fenêtre graphique et gère la simulation interactive.
Graphics 1920, 1080, 0, 60
SeedRnd MilliSecs()

' Liste globale pour stocker tous les véhicules
Global VehicleList:TList = New TList

' Variables pour gérer les modes et les entités
Global mode:Int = 0
Global modeNames$[] = ["Seek", "Flee", "Arrive", "Wander", "Pursue", "Evade", "Flocking"]
Global target:Vector2 = Vector2.Create(400, 300)

Global vehicleB:Vehicle = New Vehicle
Global enemy:Vehicle = New Vehicle
enemy.maxSpeed = 2

' Créer un groupe de 1000 véhicules pour le flocking et les ajouter à la TList
For Local i:Int = 0 Until 1000
    VehicleList.AddLast(New Vehicle)
Next

' Boucle principale
While Not KeyDown(KEY_ESCAPE)
    Cls
    
    ' Change de mode avec la touche ESPACE
    If KeyHit(KEY_SPACE)
        mode = (mode + 1) Mod modeNames.length
    EndIf
    
    ' Met à jour la position de la cible avec la souris
    target.x = MouseX()
    target.y = MouseY()
	
	SetBlend(ALPHABLEND)
    
    ' Gère les différents modes
    Select mode
		Case 0 ' Seek
		    vehicleB.Seek(target)
		    vehicleB.Update()
		    vehicleB.Draw()
		    ' Dessine la zone d'arrêt autour de la cible (blanc)
        SetColor 50, 100, 150
        SetAlpha 0.1
		    DrawOval target.x - vehicleB.arriveRadius, target.y - vehicleB.arriveRadius, vehicleB.arriveRadius * 2, vehicleB.arriveRadius * 2
		    SetAlpha 1.0
			
        Case 1 ' Flee
            vehicleB.Flee(target)
            vehicleB.Update()
            vehicleB.Draw()
			
        Case 2 ' Arrive
            vehicleB.Arrive(target)
            vehicleB.Update()
            vehicleB.Draw()
			
            ' Dessine la zone d'arrêt autour de la cible
        SetColor 50, 100, 150
        SetAlpha 0.1
            DrawOval target.x - vehicleB.arriveRadius, target.y - vehicleB.arriveRadius, vehicleB.arriveRadius * 2, vehicleB.arriveRadius * 2
            SetAlpha 1.0
        Case 3 ' Wander
            vehicleB.Wander()
            vehicleB.Update()
            vehicleB.Draw()
        Case 4 ' Pursue
            enemy.Seek(target)
            enemy.Update()
            enemy.Draw()
            vehicleB.Pursue(enemy)
            vehicleB.Update()
            vehicleB.Draw()
        Case 5 ' Evade
            enemy.Seek(target)
            enemy.Update()
            enemy.Draw()
            vehicleB.Evade(enemy)
            vehicleB.Update()
            vehicleB.Draw()
        Case 6 ' Flocking
            enemy.Update()
            enemy.Draw()
            For Local v:Vehicle = EachIn VehicleList
                v.Flock(VehicleList)
                v.Flee(target)
                v.Update()
                v.Draw()
            Next
    End Select
    
    ' Affiche le mode actuel
    SetColor 255,255,255
    DrawText "Mode: " + modeNames[mode], 10, 10
    
    ' Dessine la cible (souris)
    SetColor 255,0,0
    DrawOval(target.x - 3, target.y - 3, 6, 6)
    
    Flip
Wend
