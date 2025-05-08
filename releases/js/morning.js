//FONCTION POUR AFFICHER OU CACHER UNE PARTIE D'UNE PAGE WEB

function DivStatus(image,id){
	  var Obj = document.getElementById(id);
	  var element = document.activeElement;
	  
	  if( Obj.style.visibility=="hidden")
	  {
		// Contenu cachÃ©, le montrer
		Obj.style.visibility ="visible";
		Obj.style.display ="block";
		element.blur();
		image.title='Hide informations';
		image.src = "./images/close.ico";
		image.innerHTML='&#53';
	  }
	  else
	  {
		// Contenu visible, le cacher
		Obj.style.visibility="hidden";
		Obj.style.display ="none";
		element.blur();
		image.title='Display informations';
		image.src = "./images/open.ico";
		image.innerHTML='&#54';
	  }
	}
	
function display_ct() {
	var x = new Date()
	var txt = "Last page refresh : "
	var x1=x.toUTCString();// changing the display to UTC string
	var x2=x.getDate() + "/" + (x.getMonth() +1) + "/" + x.getFullYear();
	x2 = txt + x2 + " - " +  x.getHours( )+ ":" +  x.getMinutes() + ":" +  x.getSeconds();
	document.getElementById('RefreshPageDateTime').innerHTML = x2;
}
function audio_alarme() {
	var audio=document.createElement('audio');
	audio.setAttribute('src','./audio/alarme_chouette.mp3');
	audio.play();
}

	
	