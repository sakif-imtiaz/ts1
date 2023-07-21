module Units
  module Animations
    class Action
      attr_reader :unit, :start_tick

      def initialize(unit)
        @unit = unit
      end

      def source
        VP::Sprites::Source.new(
          bounds: VP::Helpers.rect(
            vec2(
              unit.dimensions.w * (frame_i + sheet_column_offset),
              unit.dimensions.h * sheet_row
            ).with_f,
            unit.dimensions
          ).with_f
        )
      end

      def sprite_params
        {
          source: source,
          x: unit.position.x,
          y: unit.position.y
        }.merge(custom_sprite_params)
      end

      def custom_sprite_params
        raise "Must Implement #custom_sprite_params"
      end

      def perform_tick; nil; end

      def done?; false; end

      def start!
        @start_tick = current_tick
      end

      def current_tick
        $gtk.args.state.tick_count
      end

      def elapsed_ticks
        current_tick - start_tick
      end

      def elapsed_frames
        (elapsed_ticks >> frame_speed).to_i
      end

      def frame_i
        (elapsed_frames % num_frames).to_i
      end

      def sheet_column_offset; 0; end
    end

    class Move < Action
      attr_reader :start_position, :destination, :sheet_row

      # SHEET_ROWS = {
      #   archer: 5,
      #   arrow: 0,
      # }

      def initialize(unit, sheet_row, destination, start_position=nil)
        super(unit)
        @destination = destination
        @start_position = start_position.clone || unit.standing.clone
        @sheet_row = sheet_row # SHEET_ROWS[unit.tag]
      end

      def done?
        elapsed_ticks >= run_for
      end

      def run_for
        @_run_for ||= (dist/speed).ceil
      end

      def dist
        @_dist ||= Math.sqrt(
          (destination - start_position).to_h.values.map { |v| v**2.0 }.reduce(:+)
        )
      end

      def speed
        2.0
      end

      def dv
        @_dv ||= (destination - start_position) * (speed/dist)
      end

      def num_frames; 6; end
      # def sheet_row; 5; end
      def frame_speed; 2; end
      def custom_sprite_params; { }; end
      def perform_tick
        unit.standing = unit.standing + dv
        unit.standing = destination if elapsed_ticks == (run_for - 1)
      end
    end

    class Knockback < Move
      attr_reader :angle

      def initialize(unit, sheet_row, angle, distance)
        destination = vec2(Math.cos(Math::PI*angle/180.0), Math.sin(Math::PI*angle/180.0))*distance + unit.standing
        super(unit, sheet_row, destination)
        @angle = angle
      end

      def speed
        3
      end

      def displacement
        @displacement ||= destination - start_position
      end

      def dv
        displacement*(start_tick.ease_spline(
          run_for,
          [
            [0.0, 0.33, 0.38, 0.43],
            [0.71, 0.73, 0.8, 1.0]
          ]
        ))
      end

      def perform_tick
        puts sprite_params.source.bounds.to_h
        # if elapsed_ticks > (run_for - 3)
        #   unit.position = destination - unit.visual_offset
        # else
        unit.standing = start_position + dv
        # end
      end

      def num_frames; 1; end
      # def sheet_column_offset; 6; end
      def frame_speed; 1; end
      def custom_sprite_params
        { #angle: ((angle - 90) % 180)/3,
          flip_horizontally: (angle + 90) % 360 < 180,
          # angle_anchor_x: unit.visual_offset.x,
          # angle_anchor_y: unit.visual_offset.y
        }
      end
    end


    class Idle < Action
      attr_reader :unit, :sheet_row

      def initialize(unit, sheet_row)
        super(unit)
        @sheet_row = sheet_row
      end

      def done?; false; end
      def num_frames; 6; end
      # def sheet_row; 6; end
      def frame_speed; 2; end
      def perform_tick; nil; end
      def custom_sprite_params; { }; end
    end

    class Slash < Action
      attr_reader :unit, :sheet_row, :flip_horizontally

      SLASH_PARAMS = [
        { sheet_row: 4 },
        { sheet_row: 0, },
        { sheet_row: 4, flip_horizontally: true },
        { sheet_row: 2 },
      ]

      def self.build(unit, target, backhand)
        angle = unit.standing.with_f.angle_to(target.with_f)
        dir_i = ((angle + 45.0)/90.0).floor % 4
        slash_params = SLASH_PARAMS[dir_i].clone.tap do |ap|
          ap[:sheet_row] = ap[:sheet_row] + 1 unless backhand
        end
        new(unit, slash_params.sheet_row, slash_params.flip_horizontally)
      end

      def initialize(unit, sheet_row, flip_horizontally = false)
        super(unit)
        @flip_horizontally = flip_horizontally
        @sheet_row = sheet_row
      end

      def done?; elapsed_frames >= run_for; end
      def num_frames; 6; end
      # def sheet_row; 6; end
      def frame_speed; 2; end
      def run_for; 6; end
      def perform_tick; nil; end
      def custom_sprite_params; { flip_horizontally: flip_horizontally }; end
    end

    module Archers

      class Shoot < Action
        include Arby::Attributes

        AIM_PARAMS = [
          { sheet_row: 2, arrow_params: { offset: vec2(108,64), } },
          { sheet_row: 3, arrow_params: { offset: vec2(108,64), } },
          { sheet_row: 4, arrow_params: { offset: vec2(108,64), } },
          { sheet_row: 3, flip_horizontally: true, arrow_params: { offset: vec2(108, 64) } },
          { sheet_row: 2, flip_horizontally: true, arrow_params: { offset: vec2(108, 64) } },
          { sheet_row: 1, flip_horizontally: true, arrow_params: { offset: vec2(108, 64) } },
          { sheet_row: 0, arrow_params: { offset: vec2(108,64) } },
          { sheet_row: 1, arrow_params: { offset: vec2(108,64) } }
        ]
        def self.build(unit, target)
          angle = unit.standing.with_f.angle_to(target.with_f)
          dir_i = ((angle + 22.5)/45.0).floor % 8
          aim_params = AIM_PARAMS[dir_i]
          new(unit, target, aim_params[:sheet_row], angle, aim_params[:flip_horizontally])
        end

        attr_reader :target, :sheet_row, :flip_horizontally, :angle

        def initialize(unit, target, sheet_row, angle, flip_horizontally = false)
          @unit = unit
          @target = target
          @sheet_row = sheet_row
          @angle = angle
          @flip_horizontally = flip_horizontally
        end

        def loose_arrow!(angle)
          arrow = Units::Arrow.new(unit, angle)
          Units.manager.projectiles << arrow
          arrow.start_action!(Animations::Arrows::EaseProjectile.new(arrow, target.clone, 0.0))
        end

        def perform_tick
          loose_arrow!(angle) if elapsed_ticks == (6 << frame_speed)
        end

        def archer_offset; vec2(108, 64); end
        def custom_sprite_params; { flip_horizontally: flip_horizontally }; end
        def done?; elapsed_frames >= run_for; end
        def run_for; 8; end
        def num_frames; 8; end
        def frame_speed; 2; end
      end
    end

    module Arrows
      class Projectile < Move

        def initialize(unit, sheet_row, target, initial_angle)
          super(unit, sheet_row, target)
          @initial_angle = initial_angle
        end

        def speed; 8.0; end
        def sheet_row; 1; end
        def num_frames; 1; end

        def custom_sprite_params
          super.merge({ angle: @initial_angle })
        end

        attr_reader :angle
      end

      class EaseProjectile < Action
        attr_reader :destination
        attr_accessor :angle
        # attr_reader :initial_angle

        def initialize(unit, target, initial_angle)
          self.angle = initial_angle % 360
          super(unit)
          @destination = target
        end

        def speed; 11; end
        def sheet_row; 1; end
        def num_frames; 1; end
        def frame_speed; 1; end

        def displacement
          @_displacement ||= destination - starting_position -
            vec2(
              Math.cos((Math::PI * angle)/180) * 64.0,
              Math.sin((Math::PI * angle)/180) * 64.0
            ) +
            vec2(30,15)
        end
        def distance; @_distance ||= Math.sqrt(displacement.x ** 2 + displacement.y ** 2); end

        def for_ticks; @_for_ticks ||= (distance/speed).to_i; end

        def done?
          elapsed_ticks >= (distance / speed)
        end

        def starting_position
          @starting_position ||= unit.nocked.clone
        end

        def arc_vertex_offset
          @_arc_vertex_offset ||= (displacement.x > 0) ?
                                    vec2(displacement.y/(-3.0), (displacement.x/(3.0))) :
                                    vec2(displacement.y/3.0, (displacement.x/-3.0))
        end

        def perform_tick
          arc_offset_progress = start_tick.ease_spline(
            for_ticks, [[0, 0.7, 0.7, 0]])
          target_progress = start_tick.ease(for_ticks, :identity)

          unit.position.x = starting_position.x + (displacement.x*target_progress + arc_vertex_offset.x*(arc_offset_progress)) - unit.visual_offset.x
          unit.position.y = starting_position.y + (displacement.y*target_progress + arc_vertex_offset.y*(arc_offset_progress)) - unit.visual_offset.y

          @angle = unit.nock.angle_to(destination) % 360 if for_ticks - elapsed_ticks > 5
          unit.angle = angle
        end

        # def angle
        #   @angle ||= initial_angle
        # end

        def custom_sprite_params
          { angle: angle }
        end
      end

      class Stuck < Action
        attr_reader :angle

        def initialize(unit, angle = 90.0)
          super(unit)
          @angle = angle
        end
        def update_unit!; nil; end
        def done?; false; end
        def sheet_row; 0; end
        def num_frames; 1; end
        def frame_speed; 1; end
        def custom_sprite_params; { angle: angle }; end
      end
    end

    class CompoundAction
      attr_reader :action_queue, :unit

      def initialize(unit, actions = [])
        @unit = unit
        @action_queue = actions
      end

      def start!
        current_action.start!
      end

      def done?
        action_queue.count == 1 && current_action.done?
      end

      def current_action
        action_queue.first
      end

      def perform_tick
        if current_action.done? && action_queue.count > 1
          action_queue.shift
          current_action.start!
        end
        current_action.try(:perform_tick)
      end

      def sprite_params
        current_action.sprite_params
      end

      def num_frames
        current_action.num_frames
      end

      def sheet_row
        current_action.sheet_row
      end

      def update_unit
        current_action.update_unit
      end

      def frame_speed
        current_action.frame_speed
      end
    end
  end
end
