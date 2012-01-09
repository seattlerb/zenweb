function format_date( input ) {
    var date = input.split( "T" )[0].split( "-" );
    var month = [ null,
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ][ Number(date[1]) ];

    output = date[2] + " " + month + " " + date[0];

    return output;
}

function fetch_recent_github_activity( repo ) {
    var url = "http://github.com/api/v2/json/commits/list/" +
        repo +
        "/master?callback=?";

    $.getJSON( url, function(data) {
        var commits = data.commits.slice( 0, 5 );
        var list = '';

        $.each( commits, function(i,e) {
            hash = e.id.slice( 0, 7 );
            commit_date = format_date( e.committed_date );
            github_link = "<a href=\"http://github.com/" +
                repo +
                "/commit/" + e.id + "\">" + hash + "</a>";

            list += "<li>";
            list += "<h3 class=\"date\">" + commit_date + "</h3>";
            list += "<p>[" + github_link + "] " + e.message + "</p>";
            list += "</li>";
        });

        $("ul#recent_activity").html(list);
    });
}
