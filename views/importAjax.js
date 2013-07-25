function myCallback(data) 
{
	document.getElementById('displayData').innerHTML = String(data.data["2001-10-01"]) + " | " + data["frequency"] + " | " + data["description"] ;
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

	document.getElementById('arrayDate').innerHTML = dates;
	document.getElementById('arrayVal').innerHTML = values;

	var datalist = new Array();

	for (var i = 0; i < values.length; i++) {
		datalist.push({ "x": i, "y":values[i]});
	}

	document.getElementById('arrayVal').innerHTML = values;

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
		tickFormat: function(x) {return xarray[x]}
	});


	graph.render();
}

var url = 'http://uherodata.herokuapp.com/json/';
url += '17800';
url += '?callback=myCallback';

$('document').ready(function() {
	$.ajax({
	        url: url,
	        dataType: 'jsonp',
			jsonpCallback: 'myCallback',
			jsonp: 'callback'
	    });
});