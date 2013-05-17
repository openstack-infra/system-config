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

function header(activeTabName) {
  tabsName = new Array();
  tabsLink = new Array();
  tabsName[0] = 'Status'; tabsLink[0] = 'http://status.openstack.org/';
  tabsName[1] = 'Zuul'; tabsLink[1] = 'http://status.openstack.org/zuul/';
  tabsName[2] = 'Rechecks'; tabsLink[2] = 'http://status.openstack.org/rechecks/';
  tabsName[3] = 'Release'; tabsLink[3] = 'http://status.openstack.org/release/';
  tabsName[4] = 'Reviews'; tabsLink[4] = 'http://status.openstack.org/reviews/';
  tabsName[5] = 'Bugday'; tabsLink[5] = 'http://status.openstack.org/bugday/';

  document.write(
   '<div id="header" class="container">'+
   '<div class="span-5">'+
   ' <h1 id="logo"><a href="http://status.openstack.org/">Open Stack</a></h1>'+
   '</div>\n'+
   '<div class="span-19 last blueLine">'+
   '<div id="navigation" class="span-19">'+
   '<ul id="Menu1">\n')

  for (var i = 0; i < tabsName.length; i++) {
      document.write('<li><a id="menu-'+tabsName[i]+'" href="'+tabsLink[i]+'"')
      if (tabsName[i] == activeTabName) {
          document.write(' class="current"');
      }
      document.write('>'+tabsName[i]+'</a></li>\n');
  }

  document.write(
   '</ul>'+
   '</div>'+
   '</div>'+
   '</div>')
}

function footer() {
 document.write(
  '<div class="container">'+
  '<hr>'+
  '<div id="footer">'+
  '<div class="span-4">'+
  '<h3>OpenStack</h3>'+
  '<ul>'+
  ' <li><a href="http://www.openstack.org/projects/">Projects</a></li>'+
  ' <li><a href="http://www.openstack.org/openstack-security/">OpenStack Security</a></li>'+
  ' <li><a href="http://www.openstack.org/projects/openstack-faq/">Common Questions</a></li>'+
  ' <li><a href="http://www.openstack.org/blog/">Blog</a></li>'+
  '</ul>'+
  '</div>\n'+
  '<div class="span-4">'+
  '<h3>Community</h3>'+
  '<ul>'+
  ' <li><a href="http://www.openstack.org/community/">User Groups</a></li>'+
  ' <li><a href="http://www.openstack.org/events/">Events</a></li>'+
  ' <li><a href="http://www.openstack.org/jobs/">Jobs</a></li>'+
  ' <li><a href="http://www.openstack.org/companies/">Companies</a></li>'+
  ' <li><a href="http://wiki.openstack.org/HowToContribute">Contribute</a></li>'+
  '</ul>'+
  '</div>\n'+
  '<div class="span-4">'+
  '<h3>Documentation</h3>'+
  '<ul>'+
  ' <li><a href="http://docs.openstack.org/">OpenStack Manuals</a></li>'+
  ' <li><a href="http://docs.openstack.org/diablo/openstack-compute/starter/content/">Getting Started</a></li>'+
  ' <li><a href="http://wiki.openstack.org/">Wiki</a></li>'+
  '</ul>'+
  '</div>\n'+
  '<div class="span-4 last">'+
  '<h3>Branding &amp; Legal</h3>'+
  '<ul>'+
  ' <li><a href="http://www.openstack.org/brand/">Logos &amp; Guidelines</a></li>'+
  ' <li><a href="http://www.openstack.org/brand/openstack-trademark-policy/">Trademark Policy</a></li>'+
  ' <li><a href="http://www.openstack.org/privacy/">Privacy Policy</a></li>'+
  ' <li><a href="http://wiki.openstack.org/CLA">OpenStack CLA</a></li>'+
  '</ul>'+
  '</div>'+
  '</div>'+
  '</div>')
}

