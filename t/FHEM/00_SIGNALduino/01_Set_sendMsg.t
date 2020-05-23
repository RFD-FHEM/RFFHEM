use Test2::V0;
use Test2::Tools::Compare qw{is};
use Mock::Sub;
use Test2::Tools::Compare qw{is item D};
use Test2::Todo;



#SIGNALduino_Set_sendMsg $hash set P0#0101#R3#C500
# ->Split into 	($protocol,$data,$repeats,$clock,$frequency);
# catch SIGNALduino_AddSendQueue
    my @mockData = (
		{
	#		todoReason => "reason",
			deviceName => q[dummyDuino],
			testname =>  q[set sendMsg ID:0 (P0#0101#R3#C500)],
			input	=>	q[sendMsg P0#0101#R3#C500],
			check =>  array  {
					item D();
			    	item 'SR;R=3;P0=500;P1=-8000;P2=-3500;P3=-1500;D=0103020302;';
    			},
		},
		{
			deviceName => q[dummyDuino],
			testname=>  "set sendMsg ID:17 (P17#0101#R3#C500)",
			input	=>	"sendMsg P17#0101#R3#C500",
			check =>  array {
			    	item D();
			    	item 'SR;R=3;P0=500;P1=-5000;P2=-2500;P3=-500;P4=-20000;D=01030202030302020304;';
    			},
		   
		},
		{
			deviceName => q[dummyDuino],
			testname=>  "set sendMsg ID:29 (P29#0xF7E#R4)",
			input	=>	"sendMsg P29#0xF7E#R4",
			check =>  array  {
					item D();
			    	item 'SR;R=4;P0=-8225;P1=235;P2=-470;P3=-235;P4=470;D=01212121213421212121212134;';
    			},	
		},
		{
			deviceName => q[cc1101dummyDuino],
    		cc1101_available => 1,
			testname=>  "set sendMsg ID:43 (P43#0101#R3#C500) with default frequency",
			input	=>	"sendMsg P43#0101#R3#C500",
			check =>  array  {
					item D();
			    	item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;F=10AB85550A;';
    	
		    },
		},

	);
	plan (scalar @mockData);	

my ($mock, $SIGNALduino_AddSendQueue);
	
BEGIN {
	$mock = Mock::Sub->new;
	$SIGNALduino_AddSendQueue = $mock->mock('main::SIGNALduino_AddSendQueue');
};

InternalTimer(time()+1, sub() {

	while (@mockData)
	{
		my $element = pop(@mockData);
		next if (!exists($element->{testname}));
		my $targetHash = $defs{$element->{deviceName}};
		my $todo =  (exists($element->{todoReason})) 
			? Test2::Todo->new(reason => $element->{todoReason})
			: undef;
		#$element->{pre_code}->() if (exists($element->{pre_code}));
		#$todo=$element->{todo}->() if (exists($element->{todo}));
		
		subtest "checking $element->{testname} on $element->{deviceName}" => sub {
			plan (4);	
			
			my $ret = SIGNALduino_Set_sendMsg($targetHash,split(" ",$element->{input}));
		
			is($ret,$element->{return},"Verify return value");
			is($SIGNALduino_AddSendQueue->called,1,"Verify SIGNALduino_AddSendQueue is called");
			return if ( $SIGNALduino_AddSendQueue->called == 0);
			
			my @called_args = $SIGNALduino_AddSendQueue->called_with;
			is(\@called_args,$element->{check},"Verify SIGNALduino_AddSendQueue parameters");
		
			is($ret,U(),"Verify SIGNALduino_AddSendQueue returned undef");
		
			$SIGNALduino_AddSendQueue->reset;
		};
		if (defined($todo)) {
			$todo->end;
		}
	
		#$element->{post_code}->() if (exists($element->{post_code}));
	
	};
	$SIGNALduino_AddSendQueue->unmock;

	done_testing();
	exit(0);

}, 0);

1;