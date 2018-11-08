DROP TABLE IF EXISTS sprint_issue;

SELECT
  SP."ID"                              AS SPRINTID,
  SP."NAME"                            as SPRINTNAME,
  TO_TIMESTAMP(SP."START_DATE" / 1000) AS datefrom,
  TO_TIMESTAMP(SP."END_DATE" / 1000)   AS dateinto,
  CFV.ISSUE                            AS ISSUEID,
  coalesce(est.numbervalue, 0)         as ESTIMATE,
  row_number()
  OVER (
    PARTITION BY SP."ID"
    ORDER BY random() )                AS ORDER_ID
INTO TEMPORARY TABLE sprint_issue
FROM public."customfieldvalue" CFV
  INNER JOIN public.customfield CF ON CF.ID = CFV.CUSTOMFIELD
  INNER JOIN public."AO_60DB71_SPRINT" SP ON
                                            cast(SP."ID" AS VARCHAR) = CFV.STRINGVALUE
  INNER JOIN public."AO_60DB71_RAPIDVIEW" RW ON SP."RAPID_VIEW_ID" = RW."ID"
  left join customfieldvalue est on est.customfield = 10006 and est.issue = cfv.issue
WHERE rw."NAME" = 'Algorithm' -- “”“ »Ãﬂ ¡Œ–ƒ€!!!
ORDER BY 1, 3;

DROP TABLE IF EXISTS sprint_issue_close;

select
  si.SPRINTID,
  si.ISSUEID,
  sum(prev.ESTIMATE)                                                                as sum_estimate_cum,
  sum(prev.ESTIMATE) /
  stat.sum_estimate                                                                 as pcn_estimate_cum,
  si.datefrom + sum(prev.ESTIMATE) / stat.sum_estimate * (si.dateinto :: timestamp -
                                                          si.datefrom :: timestamp) as estimated_date
INTO TEMPORARY TABLE sprint_issue_close
from (select
        ISSUEID,
        SPRINTID,
        ORDER_ID,
        datefrom,
        dateinto,
        row_number()
        over (
          partition by ISSUEID
          order by SPRINTID desc ) as rn
      from sprint_issue) as si
  join sprint_issue prev on prev.SPRINTID = si.SPRINTID and prev.ORDER_ID <= si.ORDER_ID
  join (select
          SPRINTID,
          sum(estimate) sum_estimate
        from sprint_issue
        group by SPRINTID) stat on stat.SPRINTID = si.SPRINTID
where si.rn = 1
group by si.SPRINTID,
  si.ISSUEID,
  stat.sum_estimate,
  si.datefrom,
  si.dateinto;

UPDATE jiraissue
SET created      = to_timestamp('2018-04-07', 'yyyy-mm-dd') + si.ORDER_ID * interval '1 second', -- “”“ ƒ¿“¿ Õ¿◊¿À¿ –¿¡Œ“ œŒ œ–Œ≈ “”!
  updated        = sic.estimated_date,
  resolutiondate = sic.estimated_date
FROM sprint_issue si
  join sprint_issue_close sic on sic.ISSUEID = si.ISSUEID
where jiraissue.id = si.ISSUEID;

UPDATE changegroup
SET
  created = x.newcreated
FROM (SELECT
        cg.id,
        case when ci.newstring <> 'Done'
          then date_trunc('day', si.datefrom)
        else date_trunc('day', sic.estimated_date) end + row_number()
                                                         OVER (
                                                           PARTITION BY si.SPRINTID
                                                           ORDER BY cg.created ) * INTERVAL '1 minute' -
        INTERVAL '1 day'
          AS newcreated
      FROM changeitem ci
        JOIN changegroup cg ON cg.id = ci.groupid
        JOIN sprint_issue si ON (si.ISSUEID = cg.issueid
                                 and (ci.oldstring is null or ci.oldstring <> si.SPRINTNAME)) or
                                (ci.newstring = si.SPRINTNAME and si.ORDER_ID = 1--
                                )
        LEFT JOIN sprint_issue_close sic on sic.ISSUEID = cg.issueid) x
where changegroup.id = x.id;