# Crop Agent

importImage est une application universelle iOS(8.0) permettant de recadrer les images stockées dans "Photos" pour ensuite les imprimer ou les sauvegarder dans "Photos".
Après avoir choisi la photo et un format de sortie, l'utilisateur peut appliquer les transformations geométriques habituelles à l'image, taille, position, rotation.

    > L'accès aux images est assuré par le framework "Photos" qui gère également leur mise en cache, et leur sauvegarde. 

    > L'affichage de l'image est pris en charge par un CATiledLayer qui morcelle l'image en tiles pour minimiser son emprunte mémoire tandis qu'une version basse résolution de l'image est placée arrière plan pour rendre le l'affichage des tiles plus discret.

    > "Core graphics" est utilisé pour calculer les différents rendus d'image, celui des différentes tiles comme celui de l'image résultante après transformation par l'utilisateur.
      
    > "GCD" est utilisé par décharger le thread principal des taches de rendu graphique qui s'affectuent en arrière. 
    
    > L'impression des photos est géré grace à "AirPrint"
