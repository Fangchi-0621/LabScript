clear;
% K. Shibata 2024/5/1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set to "true" if there are associated images for your stimuli
use_images = false;
ag501_address = "169.254.141.13";
echowave_path = "C:\\Program Files\\Telemed\\Echo Wave II Application\\EchoWave II";

font_size = 200;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

project_name = inputdlg('Enter the project name (one word):');
while length(regexp(project_name{1},'^[a-zA-Z]+$')) ~= 1 
    project_name = inputdlg('Please enter a valid project name (one word):');
end
project_name = project_name{1};

speaker_name = inputdlg('Enter the speaker name (three capital letters):');
while length(regexp(speaker_name{1},'^[A-Z]{3}$')) ~= 1
    speaker_name = inputdlg('Please enter a valid speaker name (three capital letters):');
end
speaker_name = speaker_name{1};

experiment_date = inputdlg('Enter experiment date (8 numbers, YYYYMMDD format):');
while length(regexp(experiment_date{1},'^[0-9]{8}$')) ~= 1
    experiment_date = inputdlg('Please enter a valid experiment date (8 numbers, YYYYMMDD format):');
end
experiment_date = experiment_date{1};

speaker_sex = questdlg('Select speaker sex:', 'Speaker Sex', 'M', 'F', 'F')

speaker_age = inputdlg("Enter participant's age:");
while length(regexp(speaker_age{1},"^[0-9]+$")) ~=1
    speaker_age = inputdlg("Enter participant's age:");
end
speaker_age = speaker_age{1};

all_modules = {'AG501','Audio','Ultrasound'};
[module_index,~] = listdlg('PromptString','Select modules.','ListString',all_modules);

modules = all_modules(module_index);

reps = inputdlg("Number of reps:");
while length(regexp(reps{1},"^[0-9]+$")) ~=1
    reps = inputdlg("Number of reps:");
end
reps = str2num(reps{1});

[wordlist_filename,path] = uigetfile('*.xlsx');
cd(path);

table_data = readtable(wordlist_filename);
stimuli_data = {};
for i=1:size(table_data,1)
    entry.stimulus = table_data{i,'Stimulus'};
    entry.ID = table_data{i,'ID'};
    stimuli_data{i} = entry;
end

session_name = strjoin({project_name, speaker_name, experiment_date},"_");

info_text = [...
    "<INFO>";...
    sprintf('	<PREFIX name = "%s" />',speaker_name);...
    sprintf('   <LOG name="%s" />',session_name);...
    sprintf('   <TIMINGS name="%s" />',session_name);...
    sprintf('   <PARTICIPANT id="%s" sex="%s" age="%s" />',speaker_name,speaker_sex,speaker_age);...
    "   <ACQHW>"...
    ];

for i = 1:length(modules)
    switch modules{i}
        case "AG501"
            info_text = [info_text;...
                '       <MODULE name="acq_AG501">';...
                sprintf('           <ADDR value="%s" />',ag501_address);...
                '       </MODULE>'...
            ];
        case "Audio"
            
            chan_answer = questdlg('Select channel number:', 'Channel Number', 'mono', 'stero', 'mono')
            if chan_answer == 'mono'
                chan = '1'
            else
                chan = '2'
            end


            sampling_rates = {'8000','11025','12000','16000','22050','24000','32000','44100','48000'};
            [srate_index,~] = listdlg('PromptString','Select sampling rate (in Hz).','SelectionMode','single','ListString',sampling_rates);
            
            srate = sampling_rates(srate_index);
            srate = srate{1};
            info_text = [info_text;...
                '       <MODULE name="acq_AUDIO">';...
                sprintf('           <AUDIO chan_num="%s" srate="%s" />', chan, srate);...
                '           <DISPLAY color="0 0 1" />';...
                '       </MODULE>'...
            ];
        case "Ultrasound"
            info_text = [info_text;...
                '       <MODULE name="acq_TELEMED">';...
                sprintf('           <EWPATH path="%s" />',echowave_path);...
                '       </MODULE>'...
            ];
    end
end

info_text = [info_text;...
    "</ACQHW>";...
    "<CSS>";...
    "body {";...
    "       background-color: 211,211,211;";...
    "}";...
    "#basic {";...
    "    margin-top:100px;";...
    "    margin-left: 50px;";...
    "    margin-right: 50px;";...
    "    font-family: Arial;";...
    sprintf("    font-size: %dpx;",font_size);...
    "    font-weight: bold;";...
    "    text-align: center;";...
    "    color: 000000;";...
    "}";...
    "</CSS>";...
    "</INFO>"...
    ];

info_text = strjoin(info_text,"\n");

def_text = [...
      "<DEFS>";...
      '    <DEFBLOCK name="MAIN" code="M" nreps="1" rand="1">';...
      '        <TEMPLATE>'...
      ];
if use_images
    def_text = [def_text;...
    '            <STIMULUS>';...
    '                <HTML><![CDATA[<div id="basic">@1<p><img src="images@0.jpg" alt="why?" width="720" height="405" style="padding-left:10"></div>]]></HTML>';...
    '            </STIMULUS>';...
    '        </TEMPLATE>'];
else
    def_text = [def_text;...
    '            <STIMULUS>';...
    '                <HTML><![CDATA[<div id="basic">@1</div>]]></HTML>';...
    '            </STIMULUS>';...
    '        </TEMPLATE>'];
end

for si = 1:length(stimuli_data)
    stimulus = stimuli_data{si};
    def_text = [def_text;sprintf('        <TOKEN a1="%s">%s</TOKEN>',stimulus.stimulus{1}, stimulus.ID{1})];
end

def_text = [def_text;"    </DEFBLOCK>";"</DEFS>"];

def_text = strjoin(def_text,"\n");

order_text = [...
    "<ORDER>";...
    '       <PAUSE prompt="Begin">';...
    '            <![CDATA[<div id="basic">Ready to begin?</div>]]>';...
    '       </PAUSE>';...
    ''];

for x = 1:reps
    order_text = [order_text;...
    sprintf('    <PAUSE prompt="Block 1 Rep %d" dur="2">',x);...
	sprintf('	<![CDATA[<div id="basic">Begin Block 1 Rep %d</div>]]>',x);...
	'       </PAUSE>';...
	'       <BLOCK name="MAIN" />'...
    ];
end
order_text = [order_text;...
'       <PAUSE prompt="End">';...
'		<![CDATA[<div id="basic">All Done – Thanks!</div>]]>';...
'   	</PAUSE>';...
'</ORDER>'];

full_text = strjoin([sprintf('<SESSION name="%s">',session_name);info_text;def_text;order_text;"</SESSION>"],"\n");

% Save to TextGrid
xml_file = fopen(sprintf('%s.xml',session_name),'w');
fprintf(xml_file,full_text);
fclose(xml_file);
fprintf("Done.\n");
