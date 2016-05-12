// Copyright (c) 2014 VMware, Inc.
// Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
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
var hashRegex = /^\#\/c\/([\d]+)((\/\d+)([.][.](\d+))?)?\/?$/;
// this regex matches CI comments
var ciRegex = /^(.* CI|Jenkins)$/;
// this regex matches "Patch set #"
var psRegex = /^(Uploaded patch set|Patch Set) (\d+)(:|\.)/;
// this regex matches merge failure messages
var mergeFailedRegex = /Merge Failed\./;
// this regex matches the name of CI systems we trust to report merge failures
var trustedCIRegex = /^(OpenStack CI|Jenkins)$/;
// this regex matches the pipeline markup
var pipelineNameRegex = /Build \w+ \((\w+) pipeline\)/;
// The url to full status information on running jobs
var zuulStatusURL = 'http://status.openstack.org/zuul';
// The json URL to check for running jobs
var zuulStatusJSON = 'https://zuul.openstack.org/status/change/';

// This is a variable to determine if we're in debugging mode, which
// lets you globally set it to see what's going on in the flow.
var hideci_debug = false;
// This is a variable to enable zuul integration, we default it off so
// that it creates no additional load, and that it's easy to turn off
// the feature.
var zuul_inline = false;

/**
 dbg(...) - prints a list of items out to the javascript
 console.log. This allows us to leave tracing in this file which is a
 no-op by default, but can be triggered if you enter a javascript
 console and set hideci_debug = true.
*/
function dbg () {
    if (hideci_debug == true) {
        for (var i = 0; i < arguments.length; i++) {
            console.log(arguments[i]);
        }
    }
}


function format_time(ms, words) {
    if (ms == null) {
        return "unknown";
    }
    var seconds = (+ms)/1000;
    var minutes = Math.floor(seconds/60);
    var hours = Math.floor(minutes/60);
    seconds = Math.floor(seconds % 60);
    minutes = Math.floor(minutes % 60);
    r = '';
    if (words) {
        if (hours) {
            r += hours;
            r += ' hr ';
        }
        r += minutes + ' min';
    } else {
        if (hours < 10) r += '0';
        r += hours + ':';
        if (minutes < 10) r += '0';
        r += minutes + ':';
        if (seconds < 10) r += '0';
        r += seconds;
    }
    return r;
}

var ci_parse_psnum = function($panel) {
    var match = psRegex.exec($panel.html());
    if (match !== null) {
        return parseInt(match[2]);
    }
    return 0;
};

var ci_parse_is_merge_conflict = function($panel) {
    return (mergeFailedRegex.exec($panel.html()) !== null);
};

var ci_find_pipeline = function($panel) {
    var match = pipelineNameRegex.exec($panel.html());
    if (match !== null) {
        return match[1];
    } else {
        return null;
    }
};

var ci_parse_results = function($panel) {
    var result_list = [];
    var test_results = $panel.find("li.comment_test");
    var pipeline = null;
    if (test_results !== null) {
        test_results.each(function(i, li) {
            var result = {};
            result["name"] = $(li).find("span.comment_test_name").find("a")[0].innerHTML;
            result["link"] = $(li).find("span.comment_test_name").find("a")[0];
            result["result"] = $(li).find("span.comment_test_result")[0];
            result_list.push(result);
        });
    }
    return result_list;
};

/***
 * function ci_group_by_pipeline - create a group by structure for iterating on pipelines
 *
 * This function takes the full list of comments, the current patch
 * number, and builds an array of (pipelinename, comments array)
 * tuples. That makes it very easy to process during the display
 * phase to ensure we only display the latest result for every
 * pipeline.
 *
 * Comments that do not have a parsable pipeline (3rd party ci
 * systems) get collapsed by name, and we specify 'check' for their
 * pipeline.
 *
 **/

var ci_group_by_pipeline = function(current, comments) {
    var pipelines = [];
    var pipeline_comments = [];
    var nonpipelines = [];
    var nonpipeline_comments = [];
    for (var i = 0; i < comments.length; i++) {
        var comment = comments[i];
        if ((comment.psnum != current) || !comment.is_ci || (comment.results.length == 0)) {
            continue;
        }
        if (comment.pipeline === null) {
            var index = nonpipelines.indexOf(comment.name);
            if (index == -1) {
                // not found, so create new entries
                nonpipelines.push(comment.name);
                nonpipeline_comments.push([comment]);
            } else {
                nonpipeline_comments[index].push(comment);
            }
        } else {
            var index = pipelines.indexOf(comment.pipeline);
            if (index == -1) {
                // not found, so create new entries
                pipelines.push(comment.pipeline);
                pipeline_comments.push([comment]);
            } else {
                pipeline_comments[index].push(comment);
            }
        }
    }

    var results = [];
    for (i = 0; i < pipelines.length; i++) {
        results.push([pipelines[i], pipeline_comments[i]]);
    }
    for (i = 0; i < nonpipeline_comments.length; i++) {
        // if you don't specify a pipline, it defaults to check
        results.push(['check', nonpipeline_comments[i]]);
    }
    return results;
};

var ci_parse_comments = function() {
    var comments = [];
    $("p").each(function() {
        var match = psRegex.exec($(this).html());
        if (match !== null) {
            var psnum = parseInt(match[2]);
            var top = $(this).parent().parent().parent();
            // old change screen
            var name = top.attr("name");
            if (!name) {
                // new change screen
                name = $(this).parent().parent().parent().children().children()[0].innerHTML;
                top = $(this).parent().parent().parent().parent();
            }
            var comment = {};
            comment.name = name;

            var date_cell = top.find(".commentPanelDateCell");
            if (date_cell.attr("title")) {
                // old change screen
                comment.date = date_cell.attr("title");
            } else {
                // new change screen
                comment.date = $(this).parent().parent().parent().children().children()[2].innerHTML
            }
            var comment_panel = $(this).parent();
            comment.psnum = psnum;
            comment.merge_conflict = ci_parse_is_merge_conflict(comment_panel);
            comment.pipeline = ci_find_pipeline(comment_panel);
            comment.results = ci_parse_results(comment_panel);
            comment.is_ci = (ciRegex.exec(comment.name) !== null);
            comment.is_trusted_ci = (trustedCIRegex.exec(comment.name) !== null);
            comment.ref = top;
            dbg("Found comment", comment);
            comments.push(comment);
        }
    });
    return comments;
};

var ci_latest_patchset = function(comments) {
    var psnum = 0;
    for (var i = 0; i < comments.length; i++) {
        psnum = Math.max(psnum, comments[i].psnum);
    }
    return psnum;
};

var ci_is_merge_conflict = function(comments) {
    var latest = ci_latest_patchset(comments);
    var conflict = false;
    for (var i = 0; i < comments.length; i++) {
        var comment = comments[i];
        // only if we are actually talking about the latest patch set
        if (comment.psnum == latest) {
            if (comment.is_trusted_ci) {
                conflict = comment.merge_conflict;
            }
        }
    }
    return conflict;
};

var ci_prepare_results_table = function() {
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
    } else {
        $(table).empty();
    }
    return table;
};

var ci_display_results = function(comments) {
    var table = ci_prepare_results_table();
    if (ci_is_merge_conflict(comments)) {
        var mc_header = $("<tr>").append($('<td class="merge_conflict" colpsan="2">Patch in Merge Conflict</td>'));
        mc_header.css('width', '400');
        mc_header.css('font-weight', 'bold');
        mc_header.css('color', 'red');
        mc_header.css('padding-left', '2em');
        $(table).append(mc_header);

        return;
    }
    var current = ci_latest_patchset(comments);
    var pipelines = ci_group_by_pipeline(current, comments);
    for (var i = 0; i < pipelines.length; i++) {
        var pipeline_name = pipelines[i][0];
        var pipeline_comments = pipelines[i][1];
        // the most recent comment on a pipeline
        var last = pipelines[i][1].length - 1;
        var comment = pipeline_comments[last];
        var rechecks = "";
        if (last > 0) {
            rechecks = " (" + last + " rechecks)";
        }

        var header = $("<tr>").append($('<td class="header">' + comment.name + " " + pipeline_name + rechecks + '</td>'));
        header.append('<td class="header ci_date">' + comment.date + '</td>');
        $(table).append(header);
        for (var j = 0; j < comment.results.length; j++) {
            var result = comment.results[j];
            var tr = $("<tr>");
            tr.append($("<td>").append($(result["link"]).clone()));
            tr.append($("<td>").append($(result["result"]).clone()));
            $(table).append(tr);
        }
    }
};

var set_cookie = function (name, value) {
    document.cookie = name + "=" + value + "; path=/";
};

var read_cookie = function (name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1, c.length);
        }
        if (c.indexOf(nameEQ) == 0) {
            return c.substring(nameEQ.length, c.length);
        }
    }
    return null;
};

var ci_toggle_visibility = function(comments, showOrHide) {
    if (!comments) {
        comments = ci_parse_comments();
    }
    $.each(comments, function(i, comment) {
        if (comment.is_ci) {
            $(comment.ref).toggle(showOrHide);
        }
    });
};

var ci_hide_ci_comments = function(comments) {
    if (!comments) {
        comments = ci_parse_comments();
    }
    $.each(comments, function(i, comment) {
        if (comment.is_ci) {
            $(comment.ref).hide();
        }
    });
};

var ci_page_loaded = function() {
    if (hashRegex.test(window.location.hash)) {
        dbg("Searching for ci results on " + window.location.hash);
        $("#toggleci").show();
        var comments = ci_parse_comments();
        ci_display_results(comments);
        var showOrHide = 'true' == read_cookie('show-ci-comments');
        if (!showOrHide) {
            ci_hide_ci_comments(comments);
        }
        if (zuul_inline === true) {
            ci_zuul_for_change(comments);
        }
    } else {
        $("#toggleci").hide();
    }
};

var ci_current_change = function() {
    var change = hashRegex.exec(window.location.hash);
    if (change.length > 1) {
        return change[1];
    }
    return null;
};

// recursively find the zuul status change, will be much more
// efficient once zuul supports since json status.
var ci_find_zuul_status = function (data, change_psnum) {
    var objects = [];
    for (var i in data) {
        if (!data.hasOwnProperty(i)) continue;
        if (typeof data[i] == 'object') {
            objects = objects.concat(ci_find_zuul_status(data[i],
                                                         change_psnum));
        } else if (i == 'id' && data.id == change_psnum) {
            objects.push(data);
        }
    }
    return objects;
};

var ci_zuul_all_status = function(jobs) {
    var status = "passing";
    for (var i = 0; i < jobs.length; i++) {
        if (jobs[i].result && jobs[i].result != "SUCCESS") {
            status = "failing";
            break;
        }
    }
    return status;
};

var ci_zuul_display_status = function(status) {
    var zuul_table = $("table.zuul_result_table")[0];
    if (!zuul_table) {
        var test_results = $("table.test_result_table")[0];
        zuul_table = document.createElement("table");
        $(zuul_table).addClass("zuul_result_table");
        $(zuul_table).addClass("infoTable").css({"margin-bottom":"1em"});
        if (test_results) {
            $(test_results).prepend(zuul_table);
        }
    }
    $(zuul_table).empty();
    $(zuul_table).show();
    $(zuul_table).append("<tr><td class='header'>Change currently being tested (<a href='" + zuulStatusURL + "'>full status</a>)</td></tr>");
    for (var i = 0; i < status.length; i++) {
        var item = status[i];
        var pipeline = item.jobs[0].pipeline;
        var passing = (item.failing_reasons && item.failing_reasons.length > 0) ? "failing" : "passing";
        var timeleft = item.remaining_time;
        var row = "<tr><td>";
        if (pipeline != null) {
            row += pipeline + " pipeline: " + passing;
            row += " (" + format_time(timeleft, false) + " left)";
        } else {
            row += "in between pipelines, status should update shortly";
        }
        row += "</td></tr>";

        $(zuul_table).append(row);
    }
};

var ci_zuul_clear_status = function () {
    var zuul_table = $("table.zuul_result_table")[0];
    if (zuul_table) {
        $(zuul_table).hide();
    }
};

var ci_zuul_process_changes = function(data, change_psnum) {
    var zuul_status = ci_find_zuul_status(data, change_psnum);
    if (zuul_status.length) {
        ci_zuul_display_status(zuul_status);
    } else {
        ci_zuul_clear_status();
    }
};

var ci_zuul_for_change = function(comments) {
    if (!comments) {
        comments = ci_parse_comments();
    }
    var change = ci_current_change();
    var psnum = ci_latest_patchset(comments);
    var change_psnum = change + "," + psnum;

    // do the loop recursively in ajax
    (function poll() {
        $.ajax({
            url: zuulStatusJSON + change_psnum,
            type: "GET",
            success: function(data) {
                dbg("Found zuul data for " + change_psnum, data);
                ci_zuul_process_changes(data, change_psnum);
            },
            dataType: "json",
            complete: setTimeout(function() {
                // once we are done with this cycle in the loop we
                // schedule ourselves again in the future with
                // setTimeout. However, by the time the function
                // actually gets called, other things might have
                // happened, and we may want to just dump the data
                // instead.
                //
                // the UI might have gone hidden (user was bored,
                // switched to another tab / window).
                //
                // the user may have navigated to another review url,
                // so the data returned is not relevant.
                //
                // both cases are recoverable when the user navigates
                // around, because a new "thread" gets started on
                // ci_page_load.
                //
                // BUG(sdague): there is the possibility that the user
                // navigates away from a page and back fast enough
                // that the first "thread" is not dead, and a second
                // one is started. greghaynes totally said he'd come
                // up with a way to fix that.
                if (window.zuul_enable_status_updates == false) {
                    return;
                }
                var current = ci_current_change();
                if (current && change_psnum.indexOf(current) != 0) {
                    // window url is dead, so don't schedule any more future
                    // updates for this url.
                    return;
                }
                poll();
            }, 15000),
            timeout: 5000
        });
    })();
};


window.onload = function() {
    var input = document.createElement("input");
    input.id = "toggleci";
    input.type = "button";
    input.className = "gwt-Button";
    input.value = "Toggle CI";
    input.onclick = function () {
        // Flip the cookie
        var showOrHide = 'true' == read_cookie('show-ci-comments');
        set_cookie('show-ci-comments', showOrHide ? 'false' : 'true');
        // Hide or Show existing comments based on cookie
        ci_toggle_visibility(null, !showOrHide);
    };
    document.body.appendChild(input);

    MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
    var observer = new MutationObserver(function(mutations, observer) {
        var span = $("span.rpcStatus");
        $.each(mutations, function(i, mutation) {
            if (mutation.target === span[0] &&
                mutation.attributeName === "style" &&
                (!(span.is(":visible:")))) {
                ci_page_loaded();
            }
        });
    });
    observer.observe(document, {
        subtree: true,
        attributes: true
    });

    $(document).on({
        'show.visibility': function() {
            window.zuul_enable_status_updates = true;
            ci_page_loaded();
        },
        'hide.visibility': function() {
            window.zuul_enable_status_updates = false;
        }
    });
};
