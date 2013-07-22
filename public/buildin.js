$(document).ready(function() {
	$("body").css("display", "none");
	// $(".buildMeIn").hide(0);
	$("body").fadeIn(500);
	
	$("a.transition").click(function(event){
		        event.preventDefault();
		        linkLocation = this.href;
		        $("body").fadeOut(500, redirectPage());      
	});
	
		function redirectPage() {
	    	window.location = linkLocation;
		}
		
		function redirectPage() {
			if (location.href.indexOf('reload')==-1) location.replace(location.href+'?reload');
			window.location = linkLocation;
		}
});