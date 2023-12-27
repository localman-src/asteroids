class_name ParticleManager extends Node

const hit_particles: PackedScene = preload("res://hit_particles.tscn")

func hit_particles_emitter(_position: Vector2) -> CPUParticles2D:
	var new_hit_particles: CPUParticles2D = hit_particles.instantiate()
	new_hit_particles.position = _position
	return new_hit_particles
