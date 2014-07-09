// this regex matches the hash part of review pages
var hashRegex = /^\#\/c\/[\/\d]+$/
// this regex matches CI comments
var ciRegex = / CI$/
// this regex matches "Patch set #"
var psRegex = /^Patch Set (\d+):/

ci_find_comments = function() {
    var comments = [];
    $("p").each(function() {
	var match = psRegex.exec(this.innerHTML);
	if (match !== null) {
	    var psnum = parseInt(match[1]);	    
	    var top = $(this).parent().parent().parent();
	    var name = top.attr("name");
	    if (!name) {
		top = $(this).parent().parent().parent();
		name = $(this).parent().prev().children()[0].innerHTML;
	    }
	    comments.push({"name":name, "psnum":psnum, "top":top, "comment":$(this).parent()});
	}
    });
    return comments;
};

ci_update_table = function() {
    var patchsets = []; 

    var comments = ci_find_comments();
    $.each(comments, function(comment_index, comment) {
	while (patchsets.length < comment["psnum"]) {
	    patchsets.push({});
	}
	// Search this comment for results
	var result_list = [];
	comment["comment"].find("li.comment_test").each(function(i, li) {
	    var result = {};
	    result["name"] = $(li).find("span.comment_test_name").find("a")[0].innerHTML;
	    result["link"] = $(li).find("span.comment_test_name").find("a")[0];
	    result["result"] = $(li).find("span.comment_test_result")[0];
	    result_list.push(result);
	});

	// If this comment has results
	if (result_list.length > 0) {
	    // Get the name of the system
	    var name = comment["name"];
	    // an item in patchsets is a hash of systems
	    var systems = patchsets[comment["psnum"]-1];
	    var system;
	    // Get or create the system object for this system
	    if (name in systems) {
		system = systems[name];
	    } else {
		// A system object has an ordered list of jobs (so
		// we preserve what was in the comments), and a
		// hash of results (so later runs of the same job
		// on the same patchset override previous results).
		system = {"jobs": [], "results": {}}
		systems[name] = system;
	    }
	    $.each(result_list, function(i, result) {
		// For each result, add the name of the job to the
		// ordered list if it isn't there already
		if (system["jobs"].indexOf(result["name"]) < 0) {
		    system["jobs"].push(result["name"]);
		}
		// Then set or override the result
		system["results"][result["name"]] = result;
	    });
	}
    });

    if (patchsets.length > 0) {
        // Create a table and insert it after the approval table
	var table = $("table.test_result_table")[0];
	if (!table) {
            table = document.createElement("table");
	    $(table).addClass("test_result_table");
	    $(table).addClass("infoTable").css({"margin-top":"1em", "margin-bottom":"1em"});
	    var approval_table = $("div.approvalTable");
	    if (approval_table.length) {
		var outer_table = document.createElement("table");
		$(outer_table).insertBefore(approval_table);
		var outer_table_row = document.createElement("tr");
		$(outer_table).append(outer_table_row);
		var td = document.createElement("td");
		$(outer_table_row).append(td);
		$(td).css({"vertical-align":"top"});
		$(td).append(approval_table);
		td = document.createElement("td");
		$(outer_table_row).append(td);
		$(td).css({"vertical-align":"top"});
		$(td).append(table);
	    } else {
		var big_table_row = $("div.screen>div>div>table>tbody>tr");
		var td = $(big_table_row).children()[1];
		$(td).append(table);
	    }
	    // Hide existing comments
	    ci_toggle_visibility(comments);
	} else {
	    $(table).empty();
	}
        var patchset = patchsets[patchsets.length-1];
        $.each(patchset, function(name, system) {
    	    // Add a header for each system
    	    var header = $("<tr>").append($('<td class="header" colspan="2">'+name+'</td>'));
    	    $(table).append(header)
    	    // Add the results
    	    $.each(system["jobs"], function(i, name) {
    		var result = system["results"][name]
    		var tr = $("<tr>");
    		tr.append($("<td>").append($(result["link"]).clone()));
    		tr.append($("<td>").append($(result["result"]).clone()));
    		$(table).append(tr)
    	    });
        });
    }
};

ci_page_loaded = function() {
    if (hashRegex.test(window.location.hash)) {
        $("#toggleci").show();
	ci_update_table();
    } else {
        $("#toggleci").hide();
    }
};

ci_toggle_visibility = function(comments) {
    if (!comments) {
	comments = ci_find_comments();
    }
    $.each(comments, function(i, comment) {
	if (ciRegex.exec(comment["name"])) {
	    comment["top"].toggle();
	}
    });
};

window.onload = function() {
    var input = document.createElement("input");
    input.id = "toggleci";
    input.type = "button";
    input.className = "gwt-Button";
    input.value = "Toggle CI";
    input.onclick = function() { ci_toggle_visibility(null); };
    console.log("append");
    document.body.appendChild(input);

    MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
    var observer = new MutationObserver(function(mutations, observer) {
	var span = $("span.rpcStatus");
	$.each(mutations, function(i, mutation) {
	    if (mutation.target === span[0] &&
	      	(!(span.is(":visible:")))) {
		ci_page_loaded();
	    }
	});
    });
    observer.observe(document, {
	subtree: true,
	attributes: true
    });
};
