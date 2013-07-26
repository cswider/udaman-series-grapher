function myCallback(data) 
{
	everythingElse(data);
}

function everythingElse(rdata) 
{

	var seriesData;
	seriesData = rdata;

	var dates = new Array();
	var values = new Array();

	$.each(seriesData.data, function(v, i) {
		dates.push(v);
		values.push(i);
	});

	var datalist = new Array();

	for (var i = 0; i < values.length; i++) {
		datalist.push({ "x": i, "y":values[i]});
	}

	var palette = new Rickshaw.Color.Palette( { scheme: 'spectrum2000' } );

	var graph = new Rickshaw.Graph( {
	        element: document.querySelector("#chart"),
	        width: 760,
	        height: 360,
	        renderer: 'line',
	        series: [{
				name: 'Data',
				data: datalist,
			color: "blue",
		}]
	} );

	var xTemp;

	var hoverDetail = new Rickshaw.Graph.HoverDetail( {
	    graph: graph,
	    xFormatter: function(x) { xTemp = dates[x]; return "" },
	    yFormatter: function(y) { return y + "<br>" + "Date: " + xTemp }
	} );

	var yAxis = new Rickshaw.Graph.Axis.Y({
	    graph: graph
	});


	var xAxis = new Rickshaw.Graph.Axis.X({
	    graph: graph,
		tickFormat: function(x) {return dates[x]}
	});


	graph.render();
}



$('document').ready(function() {
	var seriesNum = ''
seriesNum += document.getElementById('series').innerText;



var url = 'http://uherodata.herokuapp.com/json/';
url += seriesNum;
url += '?callback=myCallback';
	$.ajax({
	        url: url,
	        dataType: 'jsonp',
			jsonpCallback: 'myCallback',
			jsonp: 'callback'
	    });
});