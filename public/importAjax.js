function refresh(series)
{
	clearGraph()
	var url = 'http://uherodata.herokuapp.com/json/';
	url += series;
	url += '?callback=refreshCallback';
	$.ajax({
        url: url,
		dataType: 'jsonp',
		jsonpCallback: 'refreshCallback',
		jsonp: 'callback'
	});
	
}

function getGraphList()
{
	
	$.ajax({
		url: 'http://uherodata.herokuapp.com/cachedjson?callback=graphListCallback',
		dataType: 'jsonp',
		jsonpCallback: 'graphListCallback',
		jsonp: 'graphListCallback'
	});
	
}

function graphListCallback(data)
{
	graphListRefresh(data);
}

function graphListRefresh(data)
{
	var htmlString = '';
	
	for (var i = 0; i < data.length; i++) {
		htmlString += '<option>' + data[i] + '</option>'
	}
	
	$('#seriesList').html(htmlString);
}

function clearGraph() {
  $('#chart_container').html(
    '<div id="chart"></div><div id="y_axis"></div>'
  );
}

function refreshCallback(data) 
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
	
	var desc = seriesData.description;

	$('#desc').html(
		'<h3>'+desc+'</h3>'
	);

	var datalist = $.map(values, function(v, i) {
		return { "x": i, "y":v};
	});	

	var palette = new Rickshaw.Color.Palette( { scheme: 'spectrum2000' } );

	var graph = new Rickshaw.Graph( {
	        element: document.querySelector("#chart"),
	        width: 760,
	        height: 360,
	        renderer: 'line',
	        series: [{
				name: 'Data',
				data: datalist,
			color: "lightblue",
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
getGraphList();
});