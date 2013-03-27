// Copyright 2013 OpenStack Foundation
// //
// // Licensed under the Apache License, Version 2.0 (the "License"); you may
// // not use this file except in compliance with the License. You may obtain
// // a copy of the License at
// //
// //      http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing, software
// // distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// // WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// // License for the specific language governing permissions and limitations
// // under the License.

tabsName = new Array();
tabsLink = new Array();
tabsName[0] = 'Status'; tabsLink[0] = 'http://status.openstack.org/';
tabsName[1] = 'Zuul'; tabsLink[1] = 'http://status.openstack.org/zuul/';
tabsName[2] = 'Rechecks'; tabsLink[2] = 'http://status.openstack.org/rechecks/';
tabsName[3] = 'Release'; tabsLink[3] = 'http://status.openstack.org/release/';
tabsName[4] = 'Reviews'; tabsLink[4] = 'http://status.openstack.org/reviews/';
tabsName[5] = 'Bugday'; tabsLink[5] = 'http://status.openstack.org/bugday/';


document.write(
 '<div class="container">'+
 '<div id="header">'+
 '<div class="span-5">'+
 ' <h1 id="logo"><a href="http://status.openstack.org/">Open Stack</a></h1>'+
 '</div>\n'+
 '<div class="span-19 last blueLine">'+
 '<div id="navigation" class="span-19">'+
 '<ul id="Menu1">\n')

for (var i = 0; i < tabsName.length; i++) {
    document.write('<li><a id="menu-'+tabsName[i]+'" href="'+tabsLink[i]+'">'+tabsName[i] + '</a></li>\n');
}

document.write(
 '</ul>'+
 '</div>'+
 '</div>'+
 '</div>')

function setTab(id) {
    document.getElementById("menu-"+id).className="current";
}
