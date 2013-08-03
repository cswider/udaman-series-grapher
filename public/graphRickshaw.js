var palette = new Rickshaw.Color.Palette( { scheme: 'spectrum2000' } );

var graph = new Rickshaw.Graph( {
        element: document.querySelector("#chart"),
        width: 760,
        height: 360,
        renderer: 'line',
        series: [{
			name: 'Data',
			data: [
			<%@a = 0%>
			<%@array.each do |data|%>
			<%= "{ x: #{@a}, y: #{data} },"%>
			<%@a += 1%>
			<%end%>
		],
		color: "lightblue",
	}]
} );


/*var shelving = new Rickshaw.Graph.Behavior.Series.Toggle({
    graph: graph,
    legend: legend
});
*/

var xTemp;

var xarray = new Array();


<%@arrayDate.each do |data|%>
xarray.push("<%=data%>");
<%end%>


var hoverDetail = new Rickshaw.Graph.HoverDetail( {
    graph: graph,
    xFormatter: function(x) { xTemp = xarray[x]; return "" },
    yFormatter: function(y) { return Math.floor(y) + "<br>" + "Date: " + xTemp }
} );

var yAxis = new Rickshaw.Graph.Axis.Y({
    graph: graph
});


var xAxis = new Rickshaw.Graph.Axis.X({
    graph: graph,
	tickFormat: function(x) {return xarray[x]}
});


graph.render();