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
			todoReason => "reason",
			deviceName => q[dummyDuino],
			testname =>  q[set sendMsg ID:0 (P0#0101#R3#C500)],
			input	=>	q[sendMsg P0#0101#R3#C500],
			check =>  array  {
			    	item 1,'SR;R=3;P0=500;P1=-8000;P2=-3500;P3=-1500;D=0103020302;';
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
			plan (3);	
			
			my $ret = SIGNALduino_Set_sendMsg($targetHash,split(/ /xms,$element->{input}));
			is($ret,$element->{return},"Verify return value");
			is($SIGNALduino_AddSendQueue->called,1,"Verify SIGNALduino_AddSendQueue is called");
			next if ( $SIGNALduino_AddSendQueue->called == 0);
			is($SIGNALduino_AddSendQueue->called_with,$element->{check},"Verify SIGNALduino_AddSendQueue is called");
			is($ret,U(),"Verify SIGNALduino_AddSendQueue returned undef", diag $ret);
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