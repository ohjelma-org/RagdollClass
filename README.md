# RagdollClass
 RagdollClass is a simple R6 ragdoll.

## Installation
 Install [Git](https://git-scm.com/downloads) from their website.
 Install [rojo.exe](https://github.com/rojo-rbx/rojo/releases) from Rojo's releases page.

 ```
 $ git clone https://github.com/ohjelma-org/RagdollClass.git
 cd path_to_folder
 rojo serve
 ```

 You can learn how to add rojo.exe to path through this [article](https://medium.com/roblox-development/setting-up-roblox-development-with-rojo-git-sublime-text-3-and-luacheck-from-scratch-fb2ad65c7fa7).

## Documentation
 To be able to use it, 
 you need to require it from the client one time so it can setup the replication, which after you can start constructing RagdollClasses in the server-side.

 ### Constructors
  ``RagdollClass.new(Character: Character, Randomness: number)``
   Constructs a new Ragdoll. You can only do this from the server.
   Randomness value determines how random the ragdoll is. The recommended value is between 0 and 1, however you are free to go as far high up as you want.

 ### Methods
  ``Ragdoll:Enable(PointOfContact: Vector3)``
   Enables the ragdoll. There is an optional point of contact parameter, which will make the ragdoll revolve around it if provided.

  ``Ragdoll:Disable()``
   Not to be confused with RagdollClass:Destroy(). This disables the ragdoll, however it does not make the RagdollClass unuseable.
   This is useful if you know a character will ragdoll a lot.

 ### Destructors
  ``Ragdoll:Destroy()``
   This destroys the ragdoll. You cannot use it afterwards; you have to create a new Ragdoll in order to make a character ragdoll again. 