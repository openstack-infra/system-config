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
var hashRegex = /^\#\/c\/[\/\d]+$/;
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
                name = $(this).parent().prev().children()[0].innerHTML;
            }
            var comment = {};
            comment.name = name;

            var date_cell = top.find(".commentPanelDateCell");
            if (date_cell.attr("title")) {
                // old change screen
                comment.date = date_cell.attr("title");
            } else {
                // new change screen
                comment.date = $(this).parent().prev().children()[2].innerHTML;
            }
            var comment_panel = $(this).parent();
            comment.psnum = psnum;
            comment.merge_conflict = ci_parse_is_merge_conflict(comment_panel);
            comment.pipeline = ci_find_pipeline(comment_panel);
            comment.results = ci_parse_results(comment_panel);
            comment.is_ci = (ciRegex.exec(comment.name) !== null);
            comment.is_trusted_ci = (trustedCIRegex.exec(comment.name) !== null);
            comment.ref = top;
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
        $("#toggleci").show();
        var comments = ci_parse_comments();
        ci_display_results(comments);
        var showOrHide = 'true' == read_cookie('show-ci-comments');
        if (!showOrHide) {
            ci_hide_ci_comments(comments);
        }
    } else {
        $("#toggleci").hide();
    }
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
};
