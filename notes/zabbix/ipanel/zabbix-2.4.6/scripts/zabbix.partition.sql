use zabbix
ALTER TABLE `acknowledges` DROP PRIMARY KEY, ADD KEY `acknowledgedid` (`acknowledgeid`);
ALTER TABLE `alerts` DROP PRIMARY KEY, ADD KEY `alertid` (`alertid`);
ALTER TABLE `events` DROP PRIMARY KEY, ADD KEY `eventid` (`eventid`);
ALTER TABLE `history_log` DROP PRIMARY KEY, ADD PRIMARY KEY (`itemid`,`id`,`clock`);
ALTER TABLE `history_log` DROP KEY `history_log_2`;
ALTER TABLE `history_text` DROP PRIMARY KEY, ADD PRIMARY KEY (`itemid`,`id`,`clock`);
ALTER TABLE `history_text` DROP KEY `history_text_2`;

ALTER TABLE `events` PARTITION BY RANGE( clock ) (
PARTITION pNOWMON VALUES LESS THAN (UNIX_TIMESTAMP("ZZZM-01 00:00:00")),
PARTITION pNEXTMON VALUES LESS THAN (UNIX_TIMESTAMP("BBZZ-01 00:00:00"))
);

ALTER TABLE `acknowledges` PARTITION BY RANGE( clock ) (
PARTITION pNOWMON VALUES LESS THAN (UNIX_TIMESTAMP("ZZZM-01 00:00:00")),
PARTITION pNEXTMON VALUES LESS THAN (UNIX_TIMESTAMP("BBZZ-01 00:00:00"))
);

ALTER TABLE `alerts` PARTITION BY RANGE( clock ) (
PARTITION pNOWMON VALUES LESS THAN (UNIX_TIMESTAMP("ZZZM-01 00:00:00")),
PARTITION pNEXTMON VALUES LESS THAN (UNIX_TIMESTAMP("BBZZ-01 00:00:00"))
);

ALTER TABLE `trends` PARTITION BY RANGE( clock ) (
PARTITION pNOWMON VALUES LESS THAN (UNIX_TIMESTAMP("ZZZM-01 00:00:00")),
PARTITION pNEXTMON VALUES LESS THAN (UNIX_TIMESTAMP("BBZZ-01 00:00:00"))
);

ALTER TABLE `trends_uint` PARTITION BY RANGE( clock ) (
PARTITION pNOWMON VALUES LESS THAN (UNIX_TIMESTAMP("ZZZM-01 00:00:00")),
PARTITION pNEXTMON VALUES LESS THAN (UNIX_TIMESTAMP("BBZZ-01 00:00:00"))
);

ALTER TABLE `history` PARTITION BY RANGE( clock ) (
PARTITION pNOWDAY VALUES LESS THAN (UNIX_TIMESTAMP("ZBBD 00:00:00")),
PARTITION pNEXTDAY VALUES LESS THAN (UNIX_TIMESTAMP("TZZ 00:00:00"))
);

ALTER TABLE `history_log` PARTITION BY RANGE( clock ) (
PARTITION pNOWDAY VALUES LESS THAN (UNIX_TIMESTAMP("ZBBD 00:00:00")),
PARTITION pNEXTDAY VALUES LESS THAN (UNIX_TIMESTAMP("TZZ 00:00:00"))
);

ALTER TABLE `history_str` PARTITION BY RANGE( clock ) (
PARTITION pNOWDAY VALUES LESS THAN (UNIX_TIMESTAMP("ZBBD 00:00:00")),
PARTITION pNEXTDAY VALUES LESS THAN (UNIX_TIMESTAMP("TZZ 00:00:00"))
);

ALTER TABLE `history_text` PARTITION BY RANGE( clock ) (
PARTITION pNOWDAY VALUES LESS THAN (UNIX_TIMESTAMP("ZBBD 00:00:00")),
PARTITION pNEXTDAY VALUES LESS THAN (UNIX_TIMESTAMP("TZZ 00:00:00"))
);

ALTER TABLE `history_uint` PARTITION BY RANGE( clock ) (
PARTITION pNOWDAY VALUES LESS THAN (UNIX_TIMESTAMP("ZBBD 00:00:00")),
PARTITION pNEXTDAY VALUES LESS THAN (UNIX_TIMESTAMP("TZZ 00:00:00"))
);

