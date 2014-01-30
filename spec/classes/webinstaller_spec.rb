require 'spec_helper'

describe 'atomia::webinstaller' do

	# minimum set of default parameters
	let :params do
		{
			#:password		=> 'abc123',
		}
	end
    
    it { should contain_file('/etc/apache2/htpasswd.conf').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '444',
				).with_content(/webinstaller/)
	}    


end

