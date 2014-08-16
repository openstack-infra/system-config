// Copyright (c) 2014 VMware, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

// this regex matches the hash part of review pages
var hashRegex = /^\#\/c\/[\/\d]+$/
// this regex matches CI comments
var ciRegex = /^(.* CI|Jenkins)$/
// this regex matches "Patch set #"
var psRegex = /^Patch Set (\d+):/
// this regex matches merge failure messages
var mergeFailedRegex = /^Merge Failed\./
// this regex matches the name of CI systems we trust to report merge failures
var trustedCIRegex = /^(OpenStack CI|Jenkins)$/

ci_find_comments = function() {
    var comments = [];
    var last_merge_failure = null;
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
            // Search this comment for results
	    var comment_object = $(this).parent();
            var result_list = [];
            comment_object.find("li.comment_test").each(function(i, li) {
		var result = {};
		result["name"] = $(li).find("span.comment_test_name").find("a")[0].innerHTML;
		result["link"] = $(li).find("span.comment_test_name").find("a")[0];
		result["result"] = $(li).find("span.comment_test_result")[0];
		result_list.push(result);
            });

	    var comment = {"name":name, "psnum":psnum, "top":top, 
			   "merge_failure":null,
			   "results":result_list,
			   "comment":comment_object};
            comments.push(comment);

	    // Keep a pointer to the most recent merge failure message from
	    // the trusted CI system.  If there is a message from the system
	    // after it, drop the reference.  This way we end up with a pointer
	    // iff the last comment from the trusted system is a merge failure.
	    if (trustedCIRegex.exec(name) !== null) {
		if ($(this).next().length>0 &&
		    mergeFailedRegex.exec($(this).next()[0].innerHTML) !== null) {
		    last_merge_failure = comment;
		} else if (result_list.length>0) {
		    last_merge_failure = null;
		}
	    }

        }
    });
    // If the last comment from the trusted system is a merge failure,
    // mark that comment as a merge failure so it is displayed.  (We
    // want to ignore it if there was a merge failure that was
    // superceded.)
    if (last_merge_failure !== null) {
	last_merge_failure["merge_failure"] = true;
    }
    return comments;
};

ci_update_table = function() {
    var patchsets = [];

    var comments = ci_find_comments();
    $.each(comments, function(comment_index, comment) {
        while (patchsets.length < comment["psnum"]) {
	    // Whether there is a current merge failure in this
	    // patchset.
            patchsets.push({"_merge_failure": false});
        }

        // If this comment has results
        if (comment["results"].length > 0) {
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
            $.each(comment["results"], function(i, result) {
                // For each result, add the name of the job to the
                // ordered list if it isn't there already
                if (system["jobs"].indexOf(result["name"]) < 0) {
                    system["jobs"].push(result["name"]);
                }
                // Then set or override the result
                system["results"][result["name"]] = result;
            });
        }
	// The merge failure flag will only be set on a comment if it
	// is the most recent comment and is a merge failure.
	if (comment["merge_failure"] === true) {
	    patchsets[comment["psnum"]-1]["_merge_failure"] = true;
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
	if (!patchset["_merge_failure"]) {
            $.each(patchset, function(name, system) {
		if (name != "_merge_failure") {
                    // Add a header for each system
                    var header = $("<tr>").append($('<td class="header" colspan="2">'+name+'</td>'));
                    $(table).append(header);
                    // Add the results
                    $.each(system["jobs"], function(i, name) {
                        var result = system["results"][name]
                        var tr = $("<tr>");
                        tr.append($("<td>").append($(result["link"]).clone()));
                        tr.append($("<td>").append($(result["result"]).clone()));
                        $(table).append(tr)
                    });
		}
            });
	}
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
        if (ciRegex.exec(comment["name"]) &&
	    !comment["merge_failure"]) {
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
