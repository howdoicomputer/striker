package AN::Tools::Remote;

use strict;
use warnings;
use Net::SSH2;

our $VERSION    = "0.1.001";
my $THIS_FILE   = "Remote.pm";
my $THIS_MODULE = "AN::Tools::Remote";

sub new
{
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
	
	return ($self);
}

# Get a handle on the AN::Tools object. I know that technically that is a
# sibling module, but it makes more sense in this case to think of it as a
# parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	return ($self->{HANDLE}{TOOLS});
}

# This adds the given RSA key to the target machine and target user's authorized_keys file.
sub add_rsa_key_to_target
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# We don't try to divine the user, so we need to called to tell us who we're dealing with.
	my $user            = $parameter->{user};
	my $target          = $parameter->{target};
	my $key             = $parameter->{key};
	my $key_owner       = $parameter->{key_owner};
	my $password        = $parameter->{password};
	my $users_home      = $an->Get->users_home({user => $user});
	my $authorized_keys = "$users_home/.ssh/authorized_keys";
	$an->Log->entry({log_level => 3, message_key => "an_variables_0007", message_variables => {
		name1 => "user",            value1 => $user, 
		name2 => "target",          value2 => $target, 
		name3 => "key",             value3 => $key, 
		name4 => "key_owner",       value4 => $key_owner, 
		name5 => "password",        value5 => $password, 
		name6 => "users_home",      value6 => $users_home, 
		name7 => "authorized_keys", value7 => $authorized_keys,
	}, file => $THIS_FILE, line => __LINE__});
	
	# First, is the key already there?
	my $return_code = 0;
	my $shell_call  = $an->data->{path}{ssh}." $user\@$target \"".$an->data->{path}{'grep'}." -q 'ssh-rsa $key ' $authorized_keys; ".$an->data->{path}{echo}." rc:\\\$?\"";
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "shell_call", value1 => $shell_call, 
	}, file => $THIS_FILE, line => __LINE__});
	my ($error, $ssh_fh, $return) = $an->Remote->remote_call({
		target		=>	$target,
		password	=>	$an->data->{anvil}{password},
		ssh_fh		=>	"",
		'close'		=>	1,
		shell_call	=>	$shell_call,
	});
	foreach my $line (@{$return})
	{
		### TODO: Handle a rebuilt machine where the fingerprint no longer matches.
		next if not $line;
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "line", value1 => $line, 
		}, file => $THIS_FILE, line => __LINE__});
		if ($line =~ /rc:(\d+)$/)
		{
			# If the RC is 0, it exists.
			my $rc = $1;
			$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
				name1 => "rc", value1 => $rc, 
			}, file => $THIS_FILE, line => __LINE__});
			if ($rc)
			{
				# Add it.
				my $shell_call = $an->data->{path}{ssh}." $user\@$target \"".$an->data->{path}{'echo'}." 'ssh-rsa $key $key_owner' >> $authorized_keys\"";
				$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
					name1 => "shell_call", value1 => $shell_call, 
				}, file => $THIS_FILE, line => __LINE__});
				my ($error, $ssh_fh, $return) = $an->Remote->remote_call({
					target		=>	$target,
					password	=>	$password,
					ssh_fh		=>	"",
					'close'		=>	0,
					shell_call	=>	$shell_call,
				});
				foreach my $line (@{$return})
				{
					### TODO: Handle a rebuilt machine where the fingerprint no longer matches.
					next if not $line;
					$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
						name1 => "line", value1 => $line, 
					}, file => $THIS_FILE, line => __LINE__});
				}
				
				# And verify.
				$shell_call = $an->data->{path}{ssh}." $user\@$target \"".$an->data->{path}{'grep'}." -q 'ssh-rsa $key ' $authorized_keys; ".$an->data->{path}{echo}." rc:\\\$?\"";
				$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
					name1 => "shell_call", value1 => $shell_call, 
				}, file => $THIS_FILE, line => __LINE__});
				($error, $ssh_fh, $return) = $an->Remote->remote_call({
					target		=>	$target,
					password	=>	$password,
					ssh_fh		=>	$ssh_fh,
					'close'		=>	1,
					shell_call	=>	$shell_call,
				});
				foreach my $line (@{$return})
				{
					### TODO: Handle a rebuilt machine where the fingerprint no longer matches.
					next if not $line;
					$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
						name1 => "line", value1 => $line, 
					}, file => $THIS_FILE, line => __LINE__});
					if ($line =~ /rc:(\d+)$/)
					{
						# If the RC is 0, it exists.
						my $rc = $1;
						$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
							name1 => "rc", value1 => $rc, 
						}, file => $THIS_FILE, line => __LINE__});
						if ($rc)
						{
							# Failed
							$return_code = 1;
							$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
								name1 => "return_code", value1 => $return_code, 
							}, file => $THIS_FILE, line => __LINE__});
						}
						else
						{
							# Succeed.
							$return_code = 2;
							$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
								name1 => "return_code", value1 => $return_code, 
							}, file => $THIS_FILE, line => __LINE__});
						}
					}
				}
			}
		}
	}
	
	# 0 == Existed
	# 1 == Failed to add
	# 2 == Added successfully
	return($return_code);
}

# This generates an RSA key for the user.
sub generate_rsa_public_key
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# We don't try to divine the user, so we need to called to tell us who we're dealing with.
	my $user             = $parameter->{user};
	my $key_size         = $parameter->{key_size} ? $parameter->{key_size} : 8191;
	my $home             = $an->Get->users_home({user => $user});
	my $rsa_private_file = "${home}/.ssh/id_rsa";
	my $rsa_public_file  = "${rsa_private_file}.pub";
	$an->Log->entry({log_level => 3, message_key => "an_variables_0004", message_variables => {
		name1 => "user",             value1 => $user, 
		name2 => "home",             value2 => $home,
		name3 => "key_size",         value3 => $key_size,
		name4 => "rsa_private_file", value4 => $rsa_private_file,
		name5 => "rsa_public_file",  value5 => $rsa_public_file,
	}, file => $THIS_FILE, line => __LINE__});
	
	# Log that this can take time and then make the call.
	$an->Log->entry({log_level => 3, message_key => "notice_message_0006", file => $THIS_FILE, line => __LINE__});
	my $shell_call  = "
".$an->data->{path}{'ssh-keygen'}." -t rsa -N \"\" -b $key_size -f $rsa_private_file
".$an->data->{path}{'chown'}." $user:$user $rsa_private_file
".$an->data->{path}{'chown'}." $user:$user $rsa_public_file
".$an->data->{path}{'chmod'}." 600 $rsa_private_file
".$an->data->{path}{'chown'}." 644 $rsa_public_file
";
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "shell_call", value1 => $shell_call, 
	}, file => $THIS_FILE, line => __LINE__});
	open (my $file_handle, "$shell_call 2>&1 |") or $an->Alert->error({fatal => 1, title_key => "an_0003", message_key => "error_title_0014", message_variables => { shell_call => $shell_call, error => $! }, code => 2, file => "$THIS_FILE", line => __LINE__});
	while(<$file_handle>)
	{
		chomp;
		my $line = $_;
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "line", value1 => $line, 
		}, file => $THIS_FILE, line => __LINE__});
	}
	$an->Log->entry({log_level => 3, message_key => "an_variables_0002", message_variables => {
		name1 => "rsa_private_file", value1 => $rsa_private_file, 
		name2 => "rsa_public_file",  value2 => $rsa_public_file,
	}, file => $THIS_FILE, line => __LINE__});
	
	# Did it work?
	my $ok = 0;
	if (-e $rsa_private_file)
	{
		# Yup!
		$ok = 1;
		$an->Log->entry({log_level => 3, message_key => "notice_message_0007", message_variables => {
			user => $user, 
		}, file => $THIS_FILE, line => __LINE__});
	}
	else
	{
		# Failed, tell the user.
		$an->Alert->warning({message_key => "warning_title_0005", message_variables => {
			user	=>	$user,
		}, file => $THIS_FILE, line => __LINE__});
	}
	
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "ok", value1 => $ok, 
	}, file => $THIS_FILE, line => __LINE__});
	return($ok);
}

# This checks the current user's 'known_hosts' file for the presence of a given host and, if not found, uses
# 'ssh-keyscan' to add the host.
sub add_target_to_known_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $user   = $parameter->{user}; 
	my $target = $parameter->{target};
	$an->Log->entry({log_level => 3, title_key => "tools_log_0001", title_variables => { function => "add_target_to_known_hosts" }, message_key => "an_variables_0002", message_variables => { 
		name1 => "user",   value1 => $user,
		name2 => "target", value2 => $target,
	}, file => $THIS_FILE, line => __LINE__});
	
	my $users_home = $an->Get->users_home({user => $user});
	if (not $users_home)
	{
		# No sense proceeding... An error will already have been recorded.
		return("");
	}
	
	# I'll need to make sure I've seen the fingerprint before.
	my $known_hosts = "$users_home/.ssh/known_hosts";
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "known_hosts", value1 => $known_hosts, 
	}, file => $THIS_FILE, line => __LINE__});
	
	# OK, now do we have a 'known_hosts' at all?
	my $known_machine = 0;
	if (-e $known_hosts)
	{
		# Yup, see if the target is there already,
		$known_machine = $an->Remote->_check_known_hosts_for_target({target => $target, known_hosts => $known_hosts});
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "known_machine", value1 => $known_machine, 
		}, file => $THIS_FILE, line => __LINE__});
	}
	
	# If either known_hosts didn't contain this target or simply didn't exist, add it.
	if (not $known_machine)
	{
		# We don't know about this machine yet, so scan it.
		my $added = $an->Remote->_call_ssh_keyscan({user => $user, target => $target, known_hosts => $known_hosts});
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "added", value1 => $added, 
		}, file => $THIS_FILE, line => __LINE__});
		
		# Verify
		$known_machine = $an->Remote->_check_known_hosts_for_target({target => $target, known_hosts => $known_hosts});
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "known_machine", value1 => $known_machine, 
		}, file => $THIS_FILE, line => __LINE__});
		if ($known_machine)
		{
			# Successfully added!
			$an->Log->entry({log_level => 3, message_key => "notice_message_0009", message_variables => {
				target => $target, 
				user => $user, 
			}, file => $THIS_FILE, line => __LINE__});
		}
		else
		{
			# Failed to add. :(
			$an->Alert->warning({message_key => "warning_title_0007", message_variables => {
				target => $target, 
				user => $user, 
			}, file => $THIS_FILE, line => __LINE__});
			return(1);
		}
	}
	
	return(0);
}

# This does a remote call over SSH.
sub remote_call
{
	my $self      = shift;
	my $parameter = shift;
	
	my $an        = $self->parent;
	
	my $target     = $parameter->{target};
	my $port       = $parameter->{port}             ? $parameter->{port}     : 22;
	my $user       = $parameter->{user}             ? $parameter->{user}     : "root";
	my $password   = $parameter->{password}         ? $parameter->{password} : $an->data->{sys}{root_password};
	my $ssh_fh     = $parameter->{ssh_fh}           ? $parameter->{ssh_fh}   : "";
	my $close      = defined $parameter->{'close'}  ? $parameter->{'close'}  : 1;
	my $shell_call = $parameter->{shell_call};
	
	$an->Log->entry({log_level => 3, message_key => "an_variables_0007", message_variables => {
		name1 => "target",     value1 => $target,
		name2 => "port",       value2 => $port,
		name3 => "user",       value3 => $user,
		name4 => "password",   value4 => $password,
		name5 => "ssh_fh",     value5 => $ssh_fh,
		name6 => "close",      value6 => $close,
 		name7 => "shell_call", value7 => $shell_call,

	}, file => $THIS_FILE, line => __LINE__});
	
	### TODO: Make this a better looking error.
	if (not $target)
	{
		# No target...
		$an->Alert->error({fatal => 1, title_key => "an_0003", message_key => "error_message_0026", message_variables => {
			method	=>	$THIS_MODULE."->remote_call()",
			target	=>	$target, 
		}});
	}
	
	# Break out the port, if needed.
	my $state;
	my $error;
	if ($target =~ /^(.*):(\d+)$/)
	{
		$target = $1;
		$port = $2;
		if (($port < 0) || ($port > 65536))
		{
			# Variables for 'message_0373'.
			$an->Alert->error({fatal => 1, title_key => "an_0003", message_key => "error_message_0025", message_variables => {
				target	=>	$target, 
				port	=>	"$port",
			}});
		}
	}
	else
	{
		# In case the user is using ports in /etc/ssh/ssh_config, we'll want to check for an entry.
		$an->Storage->read_ssh_config();
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "hosts::${target}::port", value1 => $an->data->{hosts}{$target}{port}, 
		}, file => $THIS_FILE, line => __LINE__});
		if ($an->data->{hosts}{$target}{port})
		{
			$port = $an->data->{hosts}{$target}{port};
			$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
				name1 => "port", value1 => $port, 
			}, file => $THIS_FILE, line => __LINE__});
		}
	}
	
	# These will be merged into a single 'output' array before returning.
	my $stdout_output = [];
	my $stderr_output = [];
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "ssh_fh", value1 => $ssh_fh, 
	}, file => $THIS_FILE, line => __LINE__});
	if ($ssh_fh !~ /^Net::SSH2/)
	{
		$an->Log->entry({log_level => 3, message_key => "an_variables_0003", message_variables => {
			name1 => "user",   value1 => $user, 
			name2 => "target", value1 => $target, 
			name3 => "port",   value1 => $port, 
		}, file => $THIS_FILE, line => __LINE__});
		$ssh_fh = Net::SSH2->new();
		if (not $ssh_fh->connect($target, $port, Timeout => 10))
		{
			$an->Log->entry({log_level => 1, message_key => "an_variables_0001", message_variables => {
				name1 => "error", value1 => $@, 
			}, file => $THIS_FILE, line => __LINE__});
			if ($@ =~ /Bad hostname/)
			{
				# This is for the user
				$error = $an->String->get({key => "error_message_0027", variables => {
						target	=>	$target,
					},
				});
				# This is for our logs
				$an->Log->entry({log_level => 1, message_key => "error_message_0027", message_variables => {
					target	=>	$target,
				}, file => $THIS_FILE, line => __LINE__});
			}
			elsif ($@ =~ /Connection refused/)
			{
				# This is for the user
				$error = $an->String->get({key => "error_message_0028", variables => {
						target	=>	$target,
					},
				});
				# This is for our logs
				$an->Log->entry({log_level => 1, message_key => "error_message_0028", message_variables => {
					target	=>	$target,
				}, file => $THIS_FILE, line => __LINE__});
			}
			elsif ($@ =~ /No route to host/)
			{
				# This is for the user
				$error = $an->String->get({key => "error_message_0029", variables => {
						target	=>	$target,
					},
				});
				# This is for our logs
				$an->Log->entry({log_level => 1, message_key => "error_message_0029", message_variables => {
					target	=>	$target,
				}, file => $THIS_FILE, line => __LINE__});
			}
			elsif ($@ =~ /timeout/)
			{
				# This is for the user
				$error = $an->String->get({key => "error_message_0030", variables => {
						target	=>	$target,
					},
				});
				# This is for our logs
				$an->Log->entry({log_level => 1, message_key => "error_message_0030", message_variables => {
					target	=>	$target,
				}, file => $THIS_FILE, line => __LINE__});
			}
			else
			{
				# This is for the user
				$error = $an->String->get({key => "error_message_0031", variables => {
						target	=>	$target,
					},
				});
				# This is for our logs
				$an->Log->entry({log_level => 1, message_key => "error_message_0031", message_variables => {
					target	=>	$target,
				}, file => $THIS_FILE, line => __LINE__});
			}
		}
		$an->Log->entry({log_level => 3, message_key => "an_variables_0002", message_variables => {
			name1 => "error",  value1 => $error, 
			name2 => "ssh_fh", value2 => $ssh_fh, 
		}, file => $THIS_FILE, line => __LINE__});
		if (not $error)
		{
			$an->Log->entry({log_level => 3, message_key => "an_variables_0002", message_variables => {
				name1 => "user",     value1 => $user, 
				name2 => "password", value2 => $password, 
			}, file => $THIS_FILE, line => __LINE__});
			if (not $ssh_fh->auth_password($user, $password)) 
			{
				# This is for the user
				$error = $an->String->get({key => "error_message_0032", variables => {
						target	=>	$target,
					},
				});
				# This is for our logs
				$an->Log->entry({log_level => 1, message_key => "error_message_0032", message_variables => {
					target	=>	$target,
				}, file => $THIS_FILE, line => __LINE__});
			}
			else
			{
				$an->Log->entry({log_level => 3, message_key => "notice_message_0004", message_variables => {
					target => $target, 
				}, file => $THIS_FILE, line => __LINE__});
			}
		}
	}
	
	### Special thanks to Rafael Kitover (rkitover@gmail.com), maintainer of Net::SSH2, for helping me
	### sort out the polling and data collection in this section.
	#
	# Open a channel and make the call.
	$an->Log->entry({log_level => 3, message_key => "an_variables_0002", message_variables => {
		name1 => "error",  value1 => $error, 
		name2 => "ssh_fh", value2 => $ssh_fh, 
	}, file => $THIS_FILE, line => __LINE__});
	if (($ssh_fh =~ /^Net::SSH2/) && (not $error))
	{
		# We need to open a channel every time for 'exec' calls. We want to keep blocking off, but we
		# need to enable it for the channel() call.
		   $ssh_fh->blocking(1);
		my $channel = $ssh_fh->channel();
		   $ssh_fh->blocking(0);
		
		# Make the shell call
		if (not $channel)
		{
			# ... or not.
			$error = $an->String->get({key => "error_message_0033", variables => {
					target		=>	$target,
					shell_call	=>	$shell_call
				},
			});
			$ssh_fh = "";
		}
		else
		{
			$an->Log->entry({log_level => 3, message_key => "an_variables_0002", message_variables => {
				name1 => "channel",    value1 => $channel, 
				name2 => "shell_call", value2 => $shell_call, 
			}, file => $THIS_FILE, line => __LINE__});
			$channel->exec("$shell_call");
			
			# This keeps the connection open when the remote side is slow to return data, like in
			# '/etc/init.d/rgmanager stop'.
			my @poll = {
				handle => $channel,
				events => [qw/in err/],
			};
			
			# We'll store the STDOUT and STDERR data here.
			my $stdout = "";
			my $stderr = "";
			
			# Not collect the data.
			while(1)
			{
				$ssh_fh->poll(250, \@poll);
				
				# Read in anything from STDOUT
				while($channel->read(my $chunk, 80))
				{
					$stdout .= $chunk;
				}
				while ($stdout =~ s/^(.*)\n//)
				{
					my $line = $1;
					$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
						name1 => "STDOUT line", value1 => $line, 
					}, file => $THIS_FILE, line => __LINE__});
					push @{$stdout_output}, $line;
				}
				
				# Read in anything from STDERR
				while($channel->read(my $chunk, 80, 1))
				{
					$stderr .= $chunk;
				}
				while ($stderr =~ s/^(.*)\n//)
				{
					my $line = $1;
					$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
						name1 => "STDERR line", value1 => $line, 
					}, file => $THIS_FILE, line => __LINE__});
					push @{$stderr_output}, $line;
				}
				
				# Exit when we get the end-of-file.
				last if $channel->eof;
			}
			if ($stdout)
			{
				$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
					name1 => "stdout", value1 => $stdout, 
				}, file => $THIS_FILE, line => __LINE__});
				push @{$stdout_output}, $stdout;
			}
			if ($stderr)
			{
				$an->Log->entry({log_level => 2, message_key => "an_variables_0001", message_variables => {
					name1 => "stderr", value1 => $stderr, 
				}, file => $THIS_FILE, line => __LINE__});
				push @{$stderr_output}, $stderr;
			}
		}
	}
	
	# Merge the STDOUT and STDERR
	my $output = [];
	
	foreach my $line (@{$stderr_output}, @{$stdout_output})
	{
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "line", value1 => $line, 
		}, file => $THIS_FILE, line => __LINE__});
		push @{$output}, $line;
	}
	
	# Close the connection if requested.
	if ($close)
	{
		$an->Log->entry({log_level => 3, message_key => "notice_message_0005", message_variables => {
			target => $target, 
		}, file => $THIS_FILE, line => __LINE__});
		$ssh_fh->disconnect() if $ssh_fh;
		
		# For good measure, blank both variables.
		$an->data->{target}{$target}{ssh_fh} = "";
		$ssh_fh                              = "";
	}
	
	$error = "" if not defined $error;
	return($error, $ssh_fh, $output);
};

# This checks to see if a given target machine is in the user's known_hosts file.
sub _check_known_hosts_for_target
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $target      = $parameter->{target};
	my $known_hosts = $parameter->{known_hosts};
	$an->Log->entry({log_level => 3, title_key => "tools_log_0001", title_variables => { function => "_check_known_hosts_for_target" }, message_key => "an_variables_0002", message_variables => { 
		name1 => "target",      value1 => $target,
		name2 => "known_hosts", value2 => $known_hosts,
	}, file => $THIS_FILE, line => __LINE__});
	
	# read it in and search.
	my $known_machine = 0;
	my $shell_call    = $known_hosts;
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "shell_call", value1 => $shell_call, 
	}, file => $THIS_FILE, line => __LINE__});
	open (my $file_handle, "<$shell_call") or $an->Alert->error({fatal => 1, title_key => "an_0003", message_key => "error_title_0016", message_variables => { shell_call => $shell_call, error => $! }, code => 2, file => "$THIS_FILE", line => __LINE__});
	while(<$file_handle>)
	{
		chomp;
		my $line = $_;
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "line", value1 => $line, 
		}, file => $THIS_FILE, line => __LINE__});
		if ($line =~ /$target ssh-rsa /)
		{
			# We already know this machine (or rather, we already have a fingerprint for
			# this machine).
			$known_machine = 1;
			$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
				name1 => "known_machine", value1 => $known_machine, 
			}, file => $THIS_FILE, line => __LINE__});
		}
	}
	close $file_handle;
	
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "known_machine", value1 => $known_machine, 
	}, file => $THIS_FILE, line => __LINE__});
	return($known_machine);
}

# This calls 'ssh-keyscan' to add a remote machine's fingerprint to the local user's list of known_hosts.
sub _call_ssh_keyscan
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $user        = $parameter->{user}; 
	my $target      = $parameter->{target};
	my $known_hosts = $parameter->{known_hosts};
	$an->Log->entry({log_level => 3, title_key => "tools_log_0001", title_variables => { function => "_call_ssh_keyscan" }, message_key => "an_variables_0003", message_variables => { 
		name1 => "user",        value1 => $user,
		name2 => "target",      value2 => $target,
		name3 => "known_hosts", value3 => $known_hosts,
	}, file => $THIS_FILE, line => __LINE__});

	$an->Log->entry({log_level => 3, message_key => "notice_message_0010", message_variables => {
		target => $target, 
		user   => $user, 
	}, file => $THIS_FILE, line => __LINE__});
	my $shell_call = $an->data->{path}{'ssh-keyscan'}." $target >> $known_hosts && ";
		$shell_call .= $an->data->{path}{'chown'}." $user:$user $known_hosts";
	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "shell_call", value1 => $shell_call, 
	}, file => $THIS_FILE, line => __LINE__});
	open (my $file_handle, "$shell_call 2>&1 |") or $an->Alert->error({fatal => 1, title_key => "an_0003", message_key => "error_title_0014", message_variables => { shell_call => $shell_call, error => $! }, code => 2, file => "$THIS_FILE", line => __LINE__});
	while(<$file_handle>)
	{
		chomp;
		my $line = $_;
	}
	close $file_handle;
	
	return(0);
}

1;
