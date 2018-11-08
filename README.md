# jira_hack
SQL-Script that updates some Jira board task change dates in order to distribute them inside sprints in proportion of their costs.

Prerequisites:
1. Installed Jira (tested on 6.1);
2. Access to Jira admin board and Jira DB (script designed to be used with PostgreSQL);
3. Jira board with sprints, tasks and task costs;
4. Make sure you've backed up your DB befor running this!!!

Instruction:

0. Set estimated date of all your sprints to desired sprint end date (on Jira web-board);
1. Edit script with your Jira data (change board name from 'Algorithm' to your board name);
2. Edit jiraissue update script part (change '2018-04-07' to your project start date);
3. Ensure you've backed up your data once more!
4. Run script on JiraDB;
5. Invalidate cache in jira admin;
6. Enjoy!
