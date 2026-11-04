import { build } from "esbuild";
import { chromium } from "@playwright/test";
import { readFile, mkdir } from "node:fs/promises";
import assert from "node:assert/strict";

const result=await build({
  stdin:{resolveDir:process.cwd(),loader:"tsx",contents:`
    import React from 'react';import{createRoot}from'react-dom/client';
    import{AnalyticsWorkspace}from'./src/components/analytics-workspace';
    import{CctvSamples}from'./src/components/cctv-samples';
    import{SettingsWorkspace}from'./src/components/settings-workspace';
    const root=createRoot(document.getElementById('root'));
    const rows=Array.from({length:25},(_,i)=>({id:String(i),road_name:'Road '+i,depth_cm:10,status:i%2?'verified':'pending',created_at:i<9?'2026-11-04T02:00:00Z':i<17?'2026-11-03T02:00:00Z':'2026-10-31T02:00:00Z',description:'Example report '+i}));
    if(location.pathname==='/cctv')root.render(<CctvSamples/>);
    else if(location.pathname==='/settings')SettingsWorkspace({connected:true}).then(element=>root.render(element));
    else root.render(<AnalyticsWorkspace overview={['Registered users','Roads & locations','Current flood levels','Active alerts','Emergency contacts','Evacuation centers','CCTV inventory','Audit events'].map((label,index)=>({label,value:index===6?null:index+10,detail:index===6?'Requires access to this module':'Current database count'}))} reports={rows} audit={[{id:'audit',action:'UPDATE',table_name:'road_locations',occurred_at:'2026-11-04T02:00:00Z'}]} canAudit canAnalytics initialTab="analytics" reportError={null} auditError={null}/>);
  `},bundle:true,write:false,jsx:"automatic",
  define:{"process.env":"{}","process.env.NODE_ENV":"\"development\""},
  tsconfigRaw:{compilerOptions:{jsx:"react-jsx",baseUrl:".",paths:{"@/*":["./src/*"]}}},
  plugins:[{name:"isolated-fixtures",setup(builder){
    builder.onResolve({filter:/^@\/(app\/(actions|sample-actions)|lib\/supabase)$/},args=>({path:args.path,namespace:"fixture"}));
    builder.onResolve({filter:/^\.\/route-refresh$/},()=>({path:"refresh",namespace:"fixture"}));
    builder.onLoad({filter:/.*/,namespace:"fixture"},args=>({resolveDir:process.cwd(),contents:
      args.path==="refresh"?"export function RouteRefresh(){return null}":
      args.path.includes("supabase")?`export async function database(){return{auth:{getUser:async()=>({data:{user:{email:'admin@example.test',user_metadata:{full_name:'Test Administrator'},app_metadata:{provider:'google'},last_sign_in_at:'2026-11-04T02:00:00Z',identities:[{identity_id:'google-1',provider:'google',identity_data:{email:'google@example.test',name:'Linked Google Account'}},{identity_id:'email-1',provider:'email',identity_data:{email:'email@example.test'}}]}}})}}}`:
      "export async function installSamples(){return{success:'Samples fixture saved'}}export async function login(){return{}}export async function forgot(){return{}}export async function changePassword(){return{}}export async function saveRecord(){return{}}export async function deleteOrArchiveRecord(){return{}}export async function observationChoices(){return{roads:[],reports:[]}}"
    }));
  }}],
});
const css=await readFile("src/app/globals.css","utf8");
const browser=await chromium.launch({channel:"msedge",headless:true});
try{
  const page=await browser.newPage({viewport:{width:1440,height:1000}});
  const errors=[];page.on("pageerror",error=>errors.push(error.message));
  await page.route("http://admin-ui.test/**",async route=>{
    const path=new URL(route.request().url()).pathname;
    if(path.startsWith("/sample-footage/")){
      const filename=path.split("/").pop();
      assert.ok(["hereford-flood-1.webm","hereford-flood-2.webm"].includes(filename));
      return route.fulfill({contentType:"video/webm",body:await readFile(`public/sample-footage/${filename}`)});
    }
    return route.fulfill({contentType:"text/html",body:'<div class="workspace"><main><div id="root"></div></main></div>'});
  });
  await page.route("https://www.youtube-nocookie.com/**",route=>route.fulfill({contentType:"text/html",body:"<p>Recorded video fixture</p>"}));
  await page.route("https://i.ytimg.com/**",route=>route.abort());
  async function open(path){await page.goto(`http://admin-ui.test/${path}`);await page.addStyleTag({content:css});await page.addScriptTag({content:result.outputFiles[0].text});}
  await open("analytics");
  assert.equal(await page.locator('.analytics-overview-card').count(),8);
  assert.equal(await page.locator('.analytics-overview-card strong').nth(6).textContent(),'Unavailable');
  const count=()=>page.locator(".analytics-summary-card strong").first().textContent();
  assert.equal(await count(),"25");
  const periodsBox=await page.getByRole("group",{name:"Reporting period",exact:true}).boundingBox();
  const filterButton=page.getByRole("button",{name:"Filters",exact:true});
  const filterBox=await filterButton.boundingBox();const panelBox=await page.locator(".analytics-filters").boundingBox();
  assert.ok(Math.abs((periodsBox.y+periodsBox.height/2)-(filterBox.y+filterBox.height/2))<2,"Period buttons and filter controls must share one row");
  assert.ok(filterBox.x>panelBox.x+panelBox.width/2,"Filters button must be at the top-right");
  await filterButton.click();assert.equal(await page.locator("#analytics-report-filters").isVisible(),false);
  await filterButton.click();assert.equal(await page.locator("#analytics-report-filters").isVisible(),true);
  await page.getByRole("button",{name:"Day",exact:true}).click();
  await page.getByLabel("Reference date").fill("2026-11-04");
  await page.waitForFunction(()=>document.querySelector(".analytics-summary-card strong")?.textContent==="9");
  await page.getByRole("button",{name:"Week",exact:true}).click();assert.equal(await count(),"17");
  await page.getByRole("button",{name:"Month",exact:true}).click();assert.equal(await count(),"17");
  await page.getByRole("button",{name:"Year",exact:true}).click();assert.equal(await count(),"25");
  const downloadEvent=page.waitForEvent("download");await page.getByRole("button",{name:"Download PDF"}).click();const download=await downloadEvent;
  await mkdir("artifacts",{recursive:true});await download.saveAs("artifacts/analytics-report-example.pdf");
  const pdf=await readFile("artifacts/analytics-report-example.pdf","utf8");assert.ok(pdf.startsWith("%PDF-"));assert.ok(pdf.includes("Road 24"));
  await page.locator(".analytics-switch").evaluate(element=>{
    const start=new Event("touchstart",{bubbles:true});Object.defineProperty(start,"touches",{value:[{clientX:300,clientY:20}]});element.dispatchEvent(start);
    const end=new Event("touchend",{bubbles:true});Object.defineProperty(end,"changedTouches",{value:[{clientX:100,clientY:20}]});element.dispatchEvent(end);
  });
  await page.getByRole("heading",{name:"Audit Logs",exact:true}).waitFor();
  await page.getByRole("tab",{name:"Reports & Analytics",exact:true}).click();
  await page.getByRole("tab",{name:"Audit Logs",exact:true}).click();await page.getByRole("heading",{name:"Audit Logs",exact:true}).waitFor();
  await page.getByRole("tab",{name:"Reports & Analytics",exact:true}).click();assert.equal(await count(),"25");
  console.log("Passed: sliding tabs retain filters, calendar periods, complete PDF download.");
  for(const path of ["analytics","cctv","settings"]){
    await open(path);
    if(path==="analytics")await page.getByRole("heading",{name:"Report filters"}).waitFor();
    if(path==="cctv"){
      await page.locator(".cctv-sample-card").first().waitFor();assert.equal(await page.locator(".cctv-sample-card").count(),10);
      assert.equal(await page.locator("video").count(),10);
      assert.equal(await page.locator("iframe").count(),0);
      assert.ok(await page.locator("video").evaluateAll(videos=>videos.every(video=>video.muted&&video.loop&&video.autoplay&&video.playsInline)));
      await page.waitForFunction(()=>{const video=document.querySelector("video");return video&&video.readyState>=2&&video.currentTime>0&&!video.paused;});
      await page.locator("video").first().evaluate(video=>{video.currentTime=video.duration-0.1;});
      await page.waitForFunction(()=>document.querySelector("video")?.currentTime<1,null,{timeout:10000});
      await page.getByRole("button",{name:"Pause previews"}).click();
      await page.waitForFunction(()=>[...document.querySelectorAll("video")].every(video=>video.paused));
      await page.getByRole("button",{name:"Resume previews"}).click();
    }
    if(path==="settings"){
      await page.getByText("google@example.test",{exact:true}).waitFor();assert.equal(await page.locator(".google-account-card").count(),1);
      assert.equal(await page.getByText("email@example.test",{exact:true}).count(),0);
      assert.equal(await page.getByRole("button",{name:"Load 10 sample locations"}).count(),0);
    }
    for(const width of [1440,390]){await page.setViewportSize({width,height:1000});await page.waitForTimeout(100);assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`${path} overflow at ${width}px`);}
    console.log(`Passed: ${path} desktop/mobile layout${path==="cctv"?", 10 tiles, actual muted autoplay and looping playback":""}.`);
  }
  assert.deepEqual(errors,[]);
}finally{await browser.close();}
