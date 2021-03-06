describe 'update' do
  let(:dsl) do
    <<-RUBY
      user "bob", :path=>"/developer/" do
        login_profile :password_reset_required=>true

        groups(
          "Admin",
          "SES"
        )

        policy "S3" do
          {"Statement"=>
            [{"Action"=>
               ["s3:Get*",
                "s3:List*"],
              "Effect"=>"Allow",
              "Resource"=>"*"}]}
        end
      end

      user "mary", :path=>"/staff/" do
        policy "S3" do
          {"Statement"=>
            [{"Action"=>
               ["s3:Get*",
                "s3:List*"],
              "Effect"=>"Allow",
              "Resource"=>"*"}]}
        end
      end

      group "Admin", :path=>"/admin/" do
        policy "Admin" do
          {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
        end
      end

      group "SES", :path=>"/ses/" do
        policy "ses-policy" do
          {"Statement"=>
            [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
        end
      end

      role "my-role", :path=>"/any/" do
        instance_profiles(
          "my-instance-profile"
        )

        assume_role_policy_document do
          {"Version"=>"2012-10-17",
           "Statement"=>
            [{"Sid"=>"",
              "Effect"=>"Allow",
              "Principal"=>{"Service"=>"ec2.amazonaws.com"},
              "Action"=>"sts:AssumeRole"}]}
        end

        policy "role-policy" do
          {"Statement"=>
            [{"Action"=>
               ["s3:Get*",
                "s3:List*"],
              "Effect"=>"Allow",
              "Resource"=>"*"}]}
        end
      end

      instance_profile "my-instance-profile", :path=>"/profile/"
    RUBY
  end

  let(:expected) do
    {:users=>
      {"bob"=>
        {:path=>"/developer/",
         :groups=>["Admin", "SES"],
         :attached_managed_policies=>[],
         :policies=>
          {"S3"=>
            {"Statement"=>
              [{"Action"=>["s3:Get*", "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}},
         :login_profile=>{:password_reset_required=>true}},
       "mary"=>
        {:path=>"/staff/",
         :groups=>[],
         :attached_managed_policies=>[],
         :policies=>
          {"S3"=>
            {"Statement"=>
              [{"Action"=>["s3:Get*", "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}}}},
     :groups=>
      {"Admin"=>
        {:path=>"/admin/",
          :attached_managed_policies=>[],
         :policies=>
          {"Admin"=>
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}}},
       "SES"=>
        {:path=>"/ses/",
          :attached_managed_policies=>[],
         :policies=>
          {"ses-policy"=>
            {"Statement"=>
              [{"Effect"=>"Allow",
                "Action"=>"ses:SendRawEmail",
                "Resource"=>"*"}]}}}},
     :policies=>{},
     :roles=>
      {"my-role"=>
        {:path=>"/any/",
         :assume_role_policy_document=>
          {"Version"=>"2012-10-17",
           "Statement"=>
            [{"Sid"=>"",
              "Effect"=>"Allow",
              "Principal"=>{"Service"=>"ec2.amazonaws.com"},
              "Action"=>"sts:AssumeRole"}]},
         :instance_profiles=>["my-instance-profile"],
         :max_session_duration=>3600,
         :attached_managed_policies=>[],
         :policies=>
          {"role-policy"=>
            {"Statement"=>
              [{"Action"=>["s3:Get*", "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}}}},
     :instance_profiles=>{"my-instance-profile"=>{:path=>"/profile/"}}}
  end

  before(:each) do
    apply { dsl }
  end

  context 'when no change' do
    subject { client }

    it do
      updated = apply(subject) { dsl }
      expect(updated).to be_falsey
      expect(export).to eq expected
    end
  end

  context 'when update policy' do
    let(:update_policy_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:Put*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:Put*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_policy_dsl }
      expect(updated).to be_truthy
      expected[:users]["mary"][:policies]["S3"]["Statement"][0]["Action"] = ["s3:Get*", "s3:List*", "s3:Put*"]
      expected[:groups]["SES"][:policies]["ses-policy"]["Statement"][0]["Action"] = "*"
      expected[:roles]["my-role"][:policies]["role-policy"]["Statement"][0]["Action"] = ["s3:Get*", "s3:List*", "s3:Put*"]
      expect(export).to eq expected
    end
  end

  context 'when update path' do
    let(:update_path_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/xstaff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_path_dsl }
      expect(updated).to be_truthy
      expected[:users]["mary"][:path] = "/xstaff/"
      expected[:groups]["SES"][:path] = "/ses/ses/"
      expect(export).to eq expected
    end
  end

  context 'when update path (role, instance_profile)' do
    let(:cannot_update_path_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/xxx/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/xxx/"
      RUBY
    end

    let(:logger) do
      logger = Logger.new('/dev/null')
      expect(logger).to receive(:warn).with("[WARN] Role `my-role`: 'path' cannot be updated")
      expect(logger).to receive(:warn).with("[WARN] InstanceProfile `my-instance-profile`: 'path' cannot be updated")
      logger
    end

    subject { client(logger: logger) }

    it do
      updated = apply(subject) { cannot_update_path_dsl }
      expect(updated).to be_falsey
      expect(export).to eq expected
    end
  end

  context 'when update assume_role_policy' do
    let(:update_assume_role_policy_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"SID",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_assume_role_policy_dsl }
      expect(updated).to be_truthy
      expected[:roles]["my-role"][:assume_role_policy_document]["Statement"][0]["Sid"] = "SID"
      expect(export).to eq expected
    end
  end

  context 'when update groups' do
    let(:update_groups_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_groups_dsl }
      expect(updated).to be_truthy
      expected[:users]["bob"][:groups] = ["Admin"]
      expected[:users]["mary"][:groups] = ["Admin", "SES"]
      expect(export).to eq expected
    end
  end

  context 'when update login_profile' do
    let(:update_login_profile_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>false

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_login_profile_dsl }
      expect(updated).to be_truthy
      expected[:users]["bob"][:login_profile][:password_reset_required] = false
      expect(export).to eq expected
    end
  end

  context 'when delete login_profile' do
    let(:delete_login_profile_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { delete_login_profile_dsl }
      expect(updated).to be_truthy
      expected[:users]["bob"].delete(:login_profile)
      expect(export).to eq expected
    end
  end

  context 'when delete policy' do
    let(:delete_policy_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { delete_policy_dsl }
      expect(updated).to be_truthy
      expected[:users]["bob"][:policies].delete("S3")
      expected[:groups]["SES"][:policies].delete("ses-policy")
      expected[:roles]["my-role"][:policies].delete("role-policy")
      expect(export).to eq expected
    end
  end

  context 'when update instance_profiles' do
    let(:update_instance_profiles_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile2"
          )

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
        instance_profile "my-instance-profile2", :path=>"/profile2/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_instance_profiles_dsl }
      expect(updated).to be_truthy
      expected[:roles]["my-role"][:instance_profiles] = ["my-instance-profile2"]
      expected[:instance_profiles]["my-instance-profile2"] = {:path=>"/profile2/"}
      expect(export).to eq expected
    end
  end

  context 'when update role max_session_duration' do
    let(:update_instance_profiles_dsl) do
      <<-RUBY
        user "bob", :path=>"/developer/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin",
            "SES"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end

        role "my-role", :path=>"/any/" do
          instance_profiles(
            "my-instance-profile"
          )

          max_session_policy 43200

          assume_role_policy_document do
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Sid"=>"",
                "Effect"=>"Allow",
                "Principal"=>{"Service"=>"ec2.amazonaws.com"},
                "Action"=>"sts:AssumeRole"}]}
          end

          policy "role-policy" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        instance_profile "my-instance-profile", :path=>"/profile/"
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { update_instance_profiles_dsl }
      expect(updated).to be_truthy
      expected[:roles]["my-role"][:max_session_duration] = 43200
      expect(export).to eq expected
    end
  end
end
